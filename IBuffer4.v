module IBuffer4 (
    input               CLK,
    input               RSTN,
    input               LOAD_EN,
    input               START_CALC,
    input       [1:0]   ICOL_i,
    input       [31:0]  IWord,
		input       [3:0]   ODST_i,
    output      [31:0]  IROW_o,
    output      [3:0]   ICOL_VALID, // 각 Col에서 떨어트리는 EN
    output reg  [3:0]   ODST_o,
		output reg  [1:0]		ICOL_o,
		output reg 					LOAD_EN_o
);
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin ODST_o <= 0; ICOL_o <= 0; LOAD_EN_o <= 0; end
        else if(LOAD_EN) begin 
					ODST_o <= ODST_i; 
					ICOL_o <= ICOL_i;
					LOAD_EN_o <= LOAD_EN;
				end
				else 
					begin ODST_o <= 0; ICOL_o <= 0; LOAD_EN_o <= 0; end
    end

    wire [7:0] OD_a [0:3];
    wire [2:0] ENPipe;
    wire       dummy_en_out;
		// Write : 32bit을 4개의 SREG가 8bit씩 나눠가짐
    IBuffer_col ib0 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL_i), .ENDown(START_CALC),   
			.IWord8(IWord[31:24]), .OD(OD_a[0]), .ENShift(ENPipe[0])
		);
    IBuffer_col ib1 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL_i), .ENDown(ENPipe[0]),    
			.IWord8(IWord[23:16]), .OD(OD_a[1]), .ENShift(ENPipe[1])
		);
    IBuffer_col ib2 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL_i), .ENDown(ENPipe[1]),    
			.IWord8(IWord[15:8]), .OD(OD_a[2]), .ENShift(ENPipe[2])
		);
    IBuffer_col ib3 (
			.CLK(CLK), .RSTN(RSTN), .WriteEN(LOAD_EN), .ICOL(ICOL_i), .ENDown(ENPipe[2]),    
			.IWord8(IWord[7:0]), .OD(OD_a[3]), .ENShift(dummy_en_out)
		);

    assign IROW_o = {OD_a[0], OD_a[1], OD_a[2], OD_a[3]};
    
		// 타이밍 제어를 위한 ICOL_VALID 1-Cycle Delay
		wire [3:0] icv;
		reg [3:0] icv_next; 
		always@(posedge CLK or negedge RSTN) begin
			if(~RSTN) icv_next <= 0;
			else icv_next <= icv;
		end
				
    assign icv[0] = START_CALC;
    assign icv[1] = ENPipe[0];
    assign icv[2] = ENPipe[1];
    assign icv[3] = ENPipe[2];
		assign ICOL_VALID = icv_next;
endmodule