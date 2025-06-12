module MemBuffer(
	// INPUT
	input CLK, RSTN,
	input START_CALC0, ILoad0, WLoad0, 
	input [4:0] shamt0, 
	input [1:0] ICOL0, WROW0, 
	input [3:0] ODST0,
	// OUTPUT
	output reg START_CALC1, ILoad1, WLoad1, 
	output reg [4:0] shamt1, 
	output reg [1:0] ICOL1, WROW1, 
	output reg [3:0] ODST1
);
always@(posedge CLK or negedge RSTN) begin
	if(~RSTN) begin
		START_CALC1 <= 0; ILoad1 <= 0; WLoad1 <= 0; shamt1 <= 0;  
		ICOL1 <= 0;  WROW1 <= 0;  ODST1 <= 0; 
	end
	else begin
		START_CALC1 <= START_CALC0; shamt1 <= shamt0;  
		ILoad1 <= ILoad0; WLoad1 <= WLoad0;
		ICOL1 <= ICOL0;  WROW1 <= WROW0;  ODST1 <= ODST0; 
	end
end
endmodule
