module IBuffer4 (
    input               CLK,
    input               RSTN,
    // --- 제어 신호 분리 ---
    input               LOAD_EN,        // 데이터 로드 Enable
    input               START_CALC,     // 계산 시작(쉬프트 시작) Enable
    // ----------------------
    input       [1:0]   IDST,
    input       [31:0]  IWord,
    output      [31:0]  IROW_o,
    output      [3:0]   ICOL_VALID,
    input       [3:0]   ODST_i,
    output reg  [3:0]   ODST_o
);
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) ODST_o <= 0;
        else ODST_o <= ODST_i;
    end

    // Write Enable은 LOAD_EN 신호에 따라 동작
    wire [3:0] WriteEN;
    assign WriteEN[0] = LOAD_EN & (IDST == 2'd0);
    assign WriteEN[1] = LOAD_EN & (IDST == 2'd1);
    assign WriteEN[2] = LOAD_EN & (IDST == 2'd2);
    assign WriteEN[3] = LOAD_EN & (IDST == 2'd3);

    wire [7:0] OD_a [0:3];
    wire [2:0] Shift_a;
    wire       dummy_en_out;

    // Shift 체인은 START_CALC 신호로 시작
    IBuffer_col ib0 (.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[0]), .ShiftEN(START_CALC),   .IWord(IWord), .OD(OD_a[0]), .ShiftEN_o(Shift_a[0]));
    IBuffer_col ib1 (.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[1]), .ShiftEN(Shift_a[0]),    .IWord(IWord), .OD(OD_a[1]), .ShiftEN_o(Shift_a[1]));
    IBuffer_col ib2 (.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[2]), .ShiftEN(Shift_a[1]),    .IWord(IWord), .OD(OD_a[2]), .ShiftEN_o(Shift_a[2]));
    IBuffer_col ib3 (.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[3]), .ShiftEN(Shift_a[2]),    .IWord(IWord), .OD(OD_a[3]), .ShiftEN_o(dummy_en_out));

    assign IROW_o = {OD_a[3], OD_a[2], OD_a[1], OD_a[0]};
    
    // ICOL_VALID 생성 로직은 이제 START_CALC를 기준으로 동작
    assign ICOL_VALID[0] = START_CALC & ~Shift_a[0];
    assign ICOL_VALID[1] = Shift_a[0] & ~Shift_a[1];
    assign ICOL_VALID[2] = Shift_a[1] & ~Shift_a[2];
    assign ICOL_VALID[3] = Shift_a[2] & ~dummy_en_out;
endmodule