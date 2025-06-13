module Control_v2 (
    input               CLK, RSTN, Start, 
    input               Tile_Done,      // OutputStage → 타일 끝
    input               LOAD_DONE,      // WBuffer → 4행 모임
    input               STORE_DONE,     // WBuffer → 4행 write 끝
    input       [11:0]  MNT,                // {M,N,T} 1~8

    output              LOAD_I,             // 정확히 rem_t  사이클
    output              LOAD_W,             // 정확히 rem_m 사이클
    output reg          START_CALC,         // RUN 상태에서만 1
    output              ACC,	              // n==1 일 때 1
    output reg          OMSRC,          // 1 = WBuffer가 메모리 bus 소유

    output      [1:0]   ICOL, WROW,
		output  	  [2:0] 	ROW_TOTAL,
    output      [3:0]   ODST, ADDR_I, ADDR_W,
    output      [4:0]   shamt,

    output reg          CLR_DP,
    output reg          CLR_W
);

    //------------------------------------------------------
    // 1) 런타임 파라미터 & 타일 포인터
    //------------------------------------------------------
    reg [3:0] M,N,T;
    always @(posedge CLK or negedge RSTN)
        if(!RSTN)       {M,N,T} <= 0;
        else if(Start)  {M,N,T} <= MNT;

    wire [1:0] total_t = (T > 4) ? 2'd2 : 2'd1;
    wire [1:0] total_m = (M > 4) ? 2'd2 : 2'd1;
    wire [1:0] total_n = (N > 4) ? 2'd2 : 2'd1;
		
		localparam IDLE       = 3'd0,
               CLR_OMEM   = 3'd1,
               LOAD_BOTH  = 3'd2,
               RUN        = 3'd3,
               WAIT       = 3'd4,
							 STORE_ACC  = 3'd5,
               BRANCH     = 3'd6,
               LOAD_INPUT = 3'd7;

		// State Register
		reg [2:0] state, next;
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) state <= IDLE;
        else      state <= next;
		end
		
		// 타일 카운터
    reg [1:0] t,m,n;
		wire tile_done_ok = (n==2'd1)  ? (state==STORE_ACC && STORE_DONE)
																	 : Tile_Done;

		always @(posedge CLK or negedge RSTN) begin
				if (!RSTN) {t,m,n} <= 0;
				else if (tile_done_ok) begin
						if (t < total_t-1)                  t <= t + 1'b1;
						else begin
								t <= 0;
								if (m < total_m-1)              m <= m + 1'b1;
								else begin
										m <= 0;
										n <= (n < total_n-1) ? n + 1'b1 : 0;
								end
						end
				end
		end

    //------------------------------------------------------
    // 2) 서브-카운터 범위 (rem_t, rem_m, rem_n)
    //------------------------------------------------------
    wire [2:0] rem_t = (T > ( (t<<2)+4 )) ? 3'd4 : T - (t<<2);
    wire [2:0] rem_m = (M > ( (m<<2)+4 )) ? 3'd4 : M - (m<<2);
    wire [2:0] rem_n = (N > ( (n<<2)+4 )) ? 3'd4 : N - (n<<2);
		assign ROW_TOTAL = rem_t;
    //------------------------------------------------------
    // 3) LOADING용 카운터  (3-bit 0‥4) 💡
    //------------------------------------------------------
    reg [2:0] ICnt, WCnt;

    //------------------------------------------------------
    // 5) LOAD 펄스 생성 (조합)  💡
    //------------------------------------------------------
    wire load_i_en = ( (state==LOAD_BOTH  || state==LOAD_INPUT) &&
                       (ICnt < rem_t) );
    wire load_w_en = ( (state==LOAD_BOTH) &&
                       (WCnt < rem_m) );

    assign LOAD_I = load_i_en;
    assign LOAD_W = load_w_en;

    //------------------------------------------------------
    // 6) 카운터 증분: 자기 LOAD가 1일 때만 +1  💡
    //------------------------------------------------------
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) ICnt <= 0;
        else if(load_i_en) ICnt <= ICnt + 1'b1;
        else if(state!=LOAD_BOTH && state!=LOAD_INPUT) ICnt <= 0;
    end

    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) WCnt <= 0;
        else if(load_w_en) WCnt <= WCnt + 1'b1;
        else if(state!=LOAD_BOTH) WCnt <= 0;
    end

    //------------------------------------------------------
    // 7) 주소/보조 신호
    //------------------------------------------------------
    assign ADDR_I = {n[0], t[0], ICnt[1:0]};
    assign ADDR_W = {n[0], m[0], WCnt[1:0]};
    assign ODST   = {m[0], t[0], ICnt[1:0]};
    assign ICOL   = ICnt[1:0];
    assign WROW   = WCnt[1:0];
    assign ACC    = (n == 1);

    assign shamt  = {2'b00,(3'd4-rem_n)} << 3;

    //------------------------------------------------------
    // 8) 4-cycle 타이머
    //------------------------------------------------------
    reg [1:0] cnt;
    always @(posedge CLK or negedge RSTN)
        if(!RSTN || state!=RUN) cnt <= 0;
        else cnt <= cnt + 1'b1;

    //------------------------------------------------------
    // 9) Next-state & 출력 제어
    //------------------------------------------------------
    always @(*) begin
        next      = state;
        START_CALC= (state==RUN);
        {CLR_DP, CLR_W} = 2'b00;
				OMSRC = 0;
        case(state)
        //───────────────────────────────────────────────
        IDLE:     if(Start)                next = CLR_OMEM; // 0

        CLR_OMEM:                          next = LOAD_BOTH; // 1

        LOAD_BOTH: begin // 2
            if(~load_i_en && ~load_w_en)   next = RUN;
        end

        LOAD_INPUT: begin // 3
            if(~load_i_en) next = RUN;
        end

        RUN: if(cnt==2'd3) next = WAIT;   // 4

        WAIT: begin // 5
						if(ACC) begin                 // n==1 → 누산 필요
								if(LOAD_DONE)             next = STORE_ACC;  // 버퍼 다 참
						end
						else if(Tile_Done)            next = BRANCH;
				end
				
				STORE_ACC: begin // 6
						OMSRC = 1'b1;                 // 버스 → WBuffer
						if(STORE_DONE)                next = BRANCH;
				end
							
				BRANCH: begin // 7
            if( (t==total_t-1) && (m==total_m-1) && (n==total_n-1) ) begin
                next    = IDLE;
                {CLR_DP, CLR_W} = 2'b11;                 // 모든 레지스터 flush
            end
            else if(t) begin
                next    = LOAD_INPUT;                     // 같은 W, 새 I
                CLR_DP  = 1'b1;
            end
            else begin
                next    = LOAD_BOTH;                      // 새 W + I
                {CLR_DP, CLR_W} = 2'b11;
            end
        end

        default:  next = IDLE;
        endcase
    end

endmodule


