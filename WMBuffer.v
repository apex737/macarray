module WMBuffer(
	input CLK, RSTN, WLoad1,
	input [31:0] WDATA1,
	input [4:0] shamt1,
	input [1:0] WROW1,
	output reg WLoad2,
	output reg [31:0] WDATA2,
	output reg [4:0] shamt2,
	output reg [1:0] WROW2
);
always@(posedge CLK or negedge RSTN) begin
	if(~RSTN) begin
		WDATA2 <= 0;  shamt2 <= 0;  
		WROW2 <= 0;  WLoad2 <= 0;
	end
	else begin
		WDATA2 <= WDATA1;  shamt2 <= shamt1;  
		WROW2 <= WROW1;  WLoad2 <= WLoad1;
	end
end
endmodule

