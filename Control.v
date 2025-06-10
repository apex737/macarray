module Control(
    input  CLK, RSTN, Start,
    input  [11:0] MNT,

    input Tile_Done, 			// OutputStage 가 4행 × 64bit write 완료 시 1-pulse
    output LOAD,          // Weight load (1-cycle)
    output START_CALC,    // IBuffer enable

    output [1:0] ICOL,          // 열-타일 index (T-방향)
    output [1:0] WROW,          // 행-타일 index (M-방향)

    output [3:0] ODST,          // OutputMemory 타일 주소 (0‥15)
    output [4:0] shI, shW       // 8-bit 단위 left-shift  (0,8,16,24)  = (4-valid)*8
);

// ───────── 1.  입력 레지스터 / 상수 계산
wire [3:0] M, N, T;
always@(posedge CLK, negedge RSTN) begin
    if(!RSTN) {M,N,T} <= 12'd0;
    else if(Start) {M,N,T} <= MNT;
end

wire [1:0] total_t, total_m, total_n;       
always@* begin
    total_t = (T > 4) ? 2'd2 : 2'd1;
    total_m = (M > 4) ? 2'd2 : 2'd1;
    total_n = (N > 4) ? 2'd2 : 2'd1;
end

// ───────── 2.  3-중 루프 카운터 (t, m, n)
wire [1:0] t, m, n;   // 0/1

always@(posedge CLK, negedge RSTN) begin
    if(!RSTN) begin t <= 0; m <= 0; n <= 0; end
    else if(Start) begin t <= 0; m <= 0; n <= 0; end
    else if(Tile_Done) begin
        // ───── Tile-Done 이벤트 후 next-tile 결정
        if(n + 1 < total_n) n <= n + 1; // 누산
				else begin
            n <= 0;
            if(t + 1 < total_t) t <= t + 1;  // 옆 열
						else begin
                t <= 0; // m+1 : 아래 행, 0 : 전체 행렬 끝
								m <= ( m + 1 < total_m ) ? m + 1 : 0;
            end
        end
    end
end

// ───────── 3.  FSM
localparam [1:0] 
	IDLE = 2'd0, 
	LOAD_W = 2'd1, 
	RUN = 2'd2;
	
reg [1:0] state, next;

always@(posedge CLK, negedge RSTN) begin
	if(!RSTN) state <= IDLE;
	else      state <= next;
end

wire start_calc_pulse;

always@* begin
    // 기본값
    LOAD         = 1'b0;
    START_CALC   = 1'b0;
    start_calc_pulse = 1'b0;

    case(state)
    IDLE: if(Start) begin // 첫 행-타일은 무조건 load
              LOAD = 1'b1;            
              next = LOAD_W;
          end
    LOAD_W: begin // 1-cycle weight load 완료
        start_calc_pulse = 1'b1;
        next = RUN;
    end
    RUN: begin
        START_CALC = 1'b1;            // tile-pass 동안 HIGH
        // depth-pass>0 이면서 행-타일 불변이면 weight 재-load 불필요
        if(Tile_Done) begin
            // 다음 tile 패스가 행-타일( m 증가 )이면 W re-load
            if( (n == total_n - 1) & 
								(t == total_t - 1) &
                (m + 1 < total_m ) ) LOAD = 1'b1;
                

            // 모든 연산 끝났으면 idle 복귀
            if( (n == total_n - 1) & 
								(t == total_t - 1) &
                (m == total_m - 1) ) next = IDLE;
            else if(LOAD)  next = LOAD_W;  // weight 새로 load 후 run
            else 	next = RUN;           // 같은 weight, 다음 pass 바로 run
        end
    end
    endcase
end

// ───────── 4.  shI / shW  (padding shift)  &  ODST, ICOL, WROW
wire [2:0] rem_n;  // 이번 pass 유효 column 수(0~4)
always@* begin
    rem_n = (N > ((n << 2) + 4)) ? 3'd4 : (N - ( n << 2) );
    shI   = {1'b0, (4 - rem_n)} << 3;               // (4-rem)*8  …폭 5
    shW   = shI;
end

assign ICOL = t;                                // 0 / 1
assign WROW = m;                                // 0 / 1
assign ODST = {m, t};                       // 행-타일 상위 2비트 | 열-타일

// ───────── 5.  START_CALC 1-cycle 펄스 발생 (OutputStage 초기화용)
assign start_calc_pulse;     // (LOAD_W→RUN 전이, 바로 위 FSM 블록에서 생성)

endmodule
