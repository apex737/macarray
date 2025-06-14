module WBuffer(
    input               CLK, RSTN, ACC_ctrl,
		input 			[2:0] 	ROW_TOTAL,
		input               CLR_DP,      
    // From OutputStage
    input       [3:0]   ODST_om,
    input               OMWrite_om,     // 1-pulse
    input       [63:0]  DACC,            // 누산된 64-bit

    // To Control
    output reg          LOAD_DONE,       // 4개 모이면 1-pulse
    output reg          STORE_DONE,      // 4개 write 완료 1-pulse
		output reg					INIT_DONE,

    // To Output-Memory (via OMSRC==1 MUX)
    output reg  [3:0]   ODST_wb,
    output reg          EN_wb,           // write enable
    output reg  [63:0]  WData_wb
);
    //----------------------------------------------------------------
    // 내부 버퍼 4행
    //----------------------------------------------------------------
    reg [63:0] wbank  [0:3];
    reg [3:0]  addr [0:3];
    reg [1:0]  wcnt, rcnt;
    reg        wdone;   // ROW_TOTAL 개 모였는가

    //----------------------------------------------------------------
    // 상태기
    //----------------------------------------------------------------
    localparam INIT  = 2'd0,
							 IDLE  = 2'd1,   // 모으는 중
               READY = 2'd2,   // 모였음 (LOAD_DONE)
               STORE = 2'd3;   // write
							 

    reg [1:0] state;

    //----------------------------------------------------------------
    // Row_Done 수집
    //----------------------------------------------------------------
		
		reg ACC_active;

		always @(posedge CLK or negedge RSTN) begin
				if (!RSTN) 					ACC_active <= 1'b0;
				else if(CLR_DP) 		ACC_active <= 1'b0;
				else if (ACC_ctrl) 	ACC_active <= 1'b1;  // coarse-tile 시작
				else if (state==STORE && STORE_DONE) 
														ACC_active <= 1'b0; // 누산 결과 write 까지 끝난 후
		end

		wire LOAD_ROW = (ACC_active && OMWrite_om && state==IDLE);
		integer i;
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin // 초기화
						for(i = 0; i < 4; i=i+1) begin wbank[i] <= 0; addr[i] <= 0; end
            wcnt <= 0;  wdone <= 1'b0;
        end
				else if (CLR_DP) begin
						for(i = 0; i < 4; i=i+1) begin wbank[i] <= 0; addr[i] <= 0; end
            wcnt <= 0;  wdone <= 1'b0;
				end
        else if(LOAD_ROW) begin
            wbank [wcnt] <= DACC;
            addr[wcnt] <= ODST_om;
            wcnt       <= wcnt + 1'b1;
            wdone      <= (wcnt == ROW_TOTAL-1);
        end
        else if(state==STORE && STORE_DONE) begin
						for(i = 0; i < 4; i=i+1) begin wbank[i] <= 0; addr[i] <= 0; end
            wcnt <= 0;
            wdone   <= 1'b0;
        end
    end
		
		
    // 상태 전이 & 메모리 Write 제어
		reg [3:0] init_ptr;
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            state <= INIT;
						INIT_DONE <= 0;
						init_ptr   <= 1'b0;
            LOAD_DONE  <= 1'b0;
            STORE_DONE <= 1'b0;
            EN_wb      <= 1'b0;
            ODST_wb    <= 0;
            WData_wb   <= 0;
            rcnt     <= 0;
        end
        else begin
            // 기본값(1-클럭 펄스 신호 초기화)
            LOAD_DONE  <= 1'b0;
            STORE_DONE <= 1'b0;
            EN_wb      <= 1'b0;

            case(state)
						  INIT : begin
									EN_wb    <= 1'b1;
									ODST_wb  <= init_ptr;
									WData_wb <= 64'd0;
									init_ptr <= init_ptr + 1'b1;
									if(init_ptr == 4'd15) begin
											INIT_DONE <= 1'b1;
											state     <= IDLE;
									end
							end
							
							IDLE : begin
									if(wdone) begin
											LOAD_DONE <= 1'b1;   // Control_v2 알림
											state     <= READY;
									end
							end

							READY: begin  // OMSRC = 1로 전환 
									state  <= STORE;
									rcnt <= 0;
							end

							STORE: begin
									// 4행 순차 write, EN_wb 4펄스
									EN_wb    <= 1'b1;
									ODST_wb  <= addr[rcnt];
									WData_wb <= wbank[rcnt];
									rcnt   <= rcnt + 1'b1;

									if(rcnt == ROW_TOTAL-1) begin
											STORE_DONE <= 1'b1;   // 마지막 write
											state      <= IDLE;
									end
							end

							default: state <= IDLE;
            endcase
        end
    end
endmodule
