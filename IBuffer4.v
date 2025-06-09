module IBuffer4 (
    input               CLK,
    input               RSTN,
    input               LOAD_EN,
    input               START_CALC,
    input       [1:0]   IDST,
    input       [31:0]  IWord,
    output      [31:0]  IROW_o,
    output      [3:0]   ICOL_VALID, // 각 Col에서 떨어트리는 EN
    input       [3:0]   ODST_i,
    output reg  [3:0]   ODST_o
);
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) ODST_o <= 0;
        else ODST_o <= ODST_i;
    end

    wire [3:0] WriteEN;
    assign WriteEN[0] = LOAD_EN & (IDST == 2'd0);
    assign WriteEN[1] = LOAD_EN & (IDST == 2'd1);
    assign WriteEN[2] = LOAD_EN & (IDST == 2'd2);
    assign WriteEN[3] = LOAD_EN & (IDST == 2'd3);

    wire [7:0] OD_a [0:3];
    wire [2:0] ENPipe;
    wire       dummy_en_out;

    IBuffer_col ib0 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[0]), .ENDown(START_CALC),   
			.IWord(IWord), .OD(OD_a[0]), .ENShift(ENPipe[0])
		);
    IBuffer_col ib1 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[1]), .ENDown(ENPipe[0]),    
			.IWord(IWord), .OD(OD_a[1]), .ENShift(ENPipe[1])
		);
    IBuffer_col ib2 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[2]), .ENDown(ENPipe[1]),    
			.IWord(IWord), .OD(OD_a[2]), .ENShift(ENPipe[2])
		);
    IBuffer_col ib3 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(WriteEN[3]), .ENDown(ENPipe[2]),    
			.IWord(IWord), .OD(OD_a[3]), .ENShift(dummy_en_out)
		);

    assign IROW_o = {OD_a[0], OD_a[1], OD_a[2], OD_a[3]};
    
    assign ICOL_VALID[0] = START_CALC;
    assign ICOL_VALID[1] = ENPipe[0];
    assign ICOL_VALID[2] = ENPipe[1];
    assign ICOL_VALID[3] = ENPipe[2];
endmodule