module Control(
    input  CLK, RSTN, Start,
    input  [11:0] MNT,

    input  Tile_Done,                // OutputStage 1-pulse (계산 완료)
    output reg LOAD_I, LOAD_W,       // *** 분리된 로드 신호
    output reg START_CALC,           // 4-사이클 계산 Enable

    output      [1:0] ICOL, WROW,    // 열/행 타일 인덱스
    output      [3:0] ODST,          // OutputMemory 타일 주소
    output reg [4:0] shI,  shW       // 8-bit padding shift
);

// ───────── 1. 런타임 파라미터
reg [3:0] M,N,T;
always @(posedge CLK or negedge RSTN)
    if(!RSTN)       {M,N,T} <= 12'd0;
    else if(Start)  {M,N,T} <= MNT;

// 1/2 로 타일 개수를 표현 : 1 → 1패스(≤4), 2 → 2패스(5~8)
wire [1:0] total_t = (T > 4) ? 2'd2 : 2'd1;
wire [1:0] total_m = (M > 4) ? 2'd2 : 2'd1;
wire [1:0] total_n = (N > 4) ? 2'd2 : 2'd1;

// ───────── 2. 3-중 루프 카운터 (열-타일 t → 뎁스 n → 행 m)
reg [1:0] t, m, n;
always @(posedge CLK or negedge RSTN) begin
    if(!RSTN || Start) begin t<=0; m<=0; n<=0; end
    else if(Tile_Done) begin
        if(n < total_n-1)             n <= n + 1;            // 누산 타일
        else begin
            n <= 0;
            if(t < total_t-1)         t <= t + 1;            // 옆 열
            else begin
                t <= 0;
                m <= (m < total_m-1) ? m + 1 : 0;           // 아래 행 (행렬 끝이면 0)
            end
        end
    end
end

// ───────── 3. FSM  (4-사이클 로드 & 4-사이클 계산)
localparam [2:0]
    IDLE      = 3'd0,
    LOAD_BOTH = 3'd1,   // *** I,W 동시 4-cycle
    RUN_FIRST = 3'd2,   // *** 첫 계산 4-cycle
    LOAD_I    = 3'd3,   // *** I만 4-cycle
    RUN       = 3'd4;

reg [2:0] state, next;
reg [2:0] cnt;          // 0-3 사이클 카운터

// 상태 레지스터
always @(posedge CLK or negedge RSTN)
    if(!RSTN) state <= IDLE;
    else      state <= next;

// 4-사이클 타이머
always @(posedge CLK or negedge RSTN)
    if(!RSTN || state!=next) cnt <= 0;
    else                     cnt <= cnt + 1;

// 조합 로직
always @(*) begin
    // 기본값
    {LOAD_I, LOAD_W, START_CALC} = 3'b000;
    next = state;

    case(state)
    //------------------------------------------------------------------
    IDLE: if(Start) begin
              {LOAD_I, LOAD_W} = 2'b11;              // 첫 타일: I,W 모두
              next  = LOAD_BOTH;
          end
    //------------------------------------------------------------------
    LOAD_BOTH: begin
        {LOAD_I, LOAD_W} = 2'b11;
        if(cnt==3) next = RUN_FIRST;                 // 4-cycle 종료
    end
    //------------------------------------------------------------------
    RUN_FIRST: begin
        START_CALC = 1'b1;
        if(cnt==3) next = LOAD_I;                    // 첫 계산 후 곧 I로드
    end
    //------------------------------------------------------------------
    LOAD_I: begin
        LOAD_I = 1'b1;
        if(cnt==3) next = RUN;                       // I 로드 끝 → 계산
    end
    //------------------------------------------------------------------
    RUN: begin
        START_CALC = 1'b1;
        if(cnt==3) begin                             // 4-cycle 계산 끝
            // 이 타일 계산 종료 시점에 Row-change 필요?
            if((n==total_n-1)&&(t==total_t-1)&&(m<total_m-1)) begin
                {LOAD_I, LOAD_W} = 2'b11;            // Weight도 새로
                next = LOAD_BOTH;
            end
            // 모든 연산 끝
            else if((n==total_n-1)&&(t==total_t-1)&&(m==total_m-1)) begin
                next = IDLE;
            end
            // Weight 유지 & I만 또 필요한 경우
            else begin
                LOAD_I = 1'b1;
                next = LOAD_I;
            end
        end
    end
    endcase
end

// ───────── 4. Shift & 주소 매핑
wire [2:0] rem_n = (N > ((n<<2)+4)) ? 3'd4 : (N - (n<<2));
//  (4-rem)*8 을 5-bit로: 0, 8, 16, 24
always @(*) begin
    shI = {1'b0,(4-rem_n)} << 3;
    shW = shI;
end

assign ICOL = t;          // 열-타일 index → IBuffer_col 선택
assign WROW = m;          // 행-타일 index → Weight 행 주소
assign ODST = {m,t};      // 4×4 타일 배치 그대로 OutputMemory addr

endmodule
