module IMBuffer(
	input CLK, RSTN,
	input [31:0] IDATA1,
	input START_CALC1, ILoad1,
	input [4:0] shamt1, 
	input [1:0] ICOL1,
	input [3:0] ODST1,
	
	output reg  [31:0] IDATA2,
	output reg  START_CALC2, ILoad2,
	output reg  [4:0] shamt2, 
	output reg  [1:0] ICOL2,
	output reg  [3:0] ODST2
);

always@(posedge CLK or negedge RSTN) begin
	if(~RSTN) begin
		IDATA2 <= 0;  START_CALC2 <= 0;  shamt2 <= 0;  
		ICOL2 <= 0;  ODST2 <= 0;  ILoad2 <= 0;
	end
	else begin
		IDATA2 <= IDATA1;  START_CALC2 <= START_CALC1;  shamt2 <= shamt1;  
		ICOL2 <= ICOL1;  ODST2 <= ODST1;  ILoad2 <= ILoad1;
	end
end
endmodule
