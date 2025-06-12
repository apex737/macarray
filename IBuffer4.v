module IBuffer4 (
    input               CLK,
    input               RSTN,
    input               LOAD_EN,
    input               START_CALC,
    input       [1:0]   ICOL,
    input       [31:0]  IWord,
		input       [3:0]   ODST_i,
    output      [31:0]  IROW_o,
    output      [3:0]   ICOL_VALID, // 각 Col에서 떨어트리는 EN
    output reg  [3:0]   ODST_o
);
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) ODST_o <= 0;
        else ODST_o <= ODST_i;
    end

    wire [7:0] OD_a [0:3];
    wire [2:0] ENPipe;
    wire       dummy_en_out;
		// Write : 32bit을 4개의 SREG가 8bit씩 나눠가짐
    IBuffer_col ib0 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL), .ENDown(START_CALC),   
			.IWord8(IWord[31:24]), .OD(OD_a[0]), .ENShift(ENPipe[0])
		);
    IBuffer_col ib1 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL), .ENDown(ENPipe[0]),    
			.IWord8(IWord[23:16]), .OD(OD_a[1]), .ENShift(ENPipe[1])
		);
    IBuffer_col ib2 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL), .ENDown(ENPipe[1]),    
			.IWord8(IWord[15:8]), .OD(OD_a[2]), .ENShift(ENPipe[2])
		);
    IBuffer_col ib3 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL), .ENDown(ENPipe[2]),    
			.IWord8(IWord[7:0]), .OD(OD_a[3]), .ENShift(dummy_en_out)
		);

    assign IROW_o = {OD_a[0], OD_a[1], OD_a[2], OD_a[3]};
    
    assign ICOL_VALID[0] = START_CALC;
    assign ICOL_VALID[1] = ENPipe[0];
    assign ICOL_VALID[2] = ENPipe[1];
    assign ICOL_VALID[3] = ENPipe[2];
endmodule