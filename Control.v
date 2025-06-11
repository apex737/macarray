`timescale 1ns/1ps
module Control (
    input CLK, RSTN, Start,
		input Tile_Done,    // 1-pulse – 현재 4×4 타일 연산 종료		
		input [11:0]  MNT,          // {M[11:8], N[7:4], T[3:0]}  (1~8)

    output reg LOAD_I,       // 4-cycle burst read (Input  RAM)
    output reg LOAD_W,       // 4-cycle burst read (Weight RAM)
    output reg START_CALC,   // 4-cycle calc enable (MAC array)
		output  	 ACC,

    output [1:0]   ICOL,         // 타일 내부 열 인덱스 0-3  (fast)
    output [1:0]   WROW,         // 타일 내부 행 인덱스 0-3  (fast)
    output [3:0]   ODST,         // Output-memory 타일 주소 {t,m,row}
    output [3:0]   ADDR_I,       // Input  RAM 32-bit word addr
    output [3:0]   ADDR_W,       // Weight RAM 32-bit word addr
    output [4:0]   shamt         // zero-padding shift (0/8/16/24)
);

// 런타임 매개변수
localparam  IDLE       = 3'd0,
						CLR_OMEM	 = 3'd1,
            LOAD_BOTH  = 3'd2,
            RUN  			 = 3'd3,
            WAIT     	 = 3'd4,
						BRANCH 		 = 3'd5,
            LOAD_INPUT = 3'd6;  
						
reg  [3:0] M, N, T;
always @(posedge CLK or negedge RSTN)
    if(!RSTN)       {M,N,T} <= 0;
    else if(Start)  {M,N,T} <= MNT;

wire [1:0] total_t = (T > 4) ? 2'd2 : 2'd1;
wire [1:0] total_m = (M > 4) ? 2'd2 : 2'd1;
wire [1:0] total_n = (N > 4) ? 2'd2 : 2'd1;

// Tile 포인터  (t > m > n  순으로 증가)
// 000 -> 100 -> 010 -> 110 -> 001 -> 101 -> 011 -> 111
reg t, m, n;
always @(posedge CLK or negedge RSTN) begin
    if(!RSTN || Start)
        {t,m,n} <= 0;
    else if(Tile_Done) begin
        if(t < total_t-1) 		t <= t + 1;
        else begin
            t <= 0;
            if(m < total_m-1) m <= m + 1;
            else begin
                m <= 0;
                n <= (n < total_n-1) ? n + 1 : 0;
            end
        end
    end
end

// 타일 내부 서브-카운터  (ICOL, WROW)
wire [2:0] rem_t = (T > ((t<<2)+4)) ? 3'd4 : T - (t<<2); 
wire [2:0] rem_m = (M > ((m<<2)+4)) ? 3'd4 : M - (m<<2); 
wire [2:0] rem_n = (N > ((n<<2)+4)) ? 3'd4 : N - (n<<2);

reg [1:0] ICnt, WCnt;
reg [2:0] state, next;

always @(posedge CLK or negedge RSTN) begin
    if(!RSTN || Start) begin
        ICnt <= 0;
        WCnt <= 0;
    end
    else begin
        if(state == LOAD_BOTH || state == LOAD_INPUT) 
            ICnt <= (ICnt == rem_t-1) ? 0 : ICnt + 1;
				if(state == LOAD_BOTH)
						WCnt <= (WCnt == rem_m-1) ? 0 : WCnt + 1;
		end	 
end

assign shamt = {2'b00,(3'd4-rem_n)} << 3;  // 0/8/16/24
assign ADDR_I = {n, t, ICnt};
assign ADDR_W = {n, m, WCnt};
assign ODST = {m, t, ICnt};
assign ICOL = ICnt;
assign WROW = WCnt;
assign ACC = (n == 1);

// 4-cycle LOAD / CALC  FSM
always @(posedge CLK or negedge RSTN) begin
    if(!RSTN) state <= IDLE; 
    else      state <= next;
end

// Next State Logic
	// 16-사이클 타이머 
	reg [3:0] cnt; 
	always @(posedge CLK or negedge RSTN) begin
			if(!RSTN) cnt <= 0;
			else if(state!=next)	cnt <= 0;
			else                  cnt <= cnt + 4'd1;
	end
	// FSM
	always @(*) begin
		{LOAD_I, LOAD_W, START_CALC} = 3'b000;
		next = state;
		
		case(state)
		IDLE: if (Start) next = CLR_OMEM;
		
		CLR_OMEM: begin 
			// CLR_OMEM
			next = LOAD_BOTH;
		end
		
		LOAD_BOTH: begin
				{LOAD_I, LOAD_W, START_CALC} = 3'b110;
				if(ICnt == rem_t-1 && WCnt == rem_m-1) begin  // 값이 전부 로드되면 
						next = RUN;
				end
		end
		
		RUN: begin
				{LOAD_I, LOAD_W, START_CALC} = 3'b001;
				if(cnt == 3) next = WAIT; // 4회 실행 -> IBuffer4를 전부 비워냄
		end
		
		WAIT: begin // Tile_Done까지 대기
			{LOAD_I, LOAD_W, START_CALC} = 3'b000;
			if(Tile_Done) next = BRANCH;		
		end
		
		BRANCH: begin
			{LOAD_I, LOAD_W, START_CALC} = 3'b000;
			if( (t==total_t-1) &&
					(m==total_m-1) &&
					(n==total_n-1) )
									next = IDLE;   // 끝
			else if(t)
					next = LOAD_INPUT; // 같은 Weight, 다음 I-로드
			else
					next = LOAD_BOTH;  // 다음 I/W
					
		end

		LOAD_INPUT: begin
				{LOAD_I, LOAD_W, START_CALC} = 3'b100;
				if(ICnt == rem_t-1) next = RUN;
		end

		endcase
	end

endmodule

