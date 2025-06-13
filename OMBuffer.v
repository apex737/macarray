module OMBuffer(
	input CLK, RSTN,
	input [3:0] ODST_o,
	input OMWrite_o,
	input [63:0] OMEM_Data_o,
	output reg [3:0] ODST_om,
	output reg OMWrite_om,
	output reg [63:0] OMEM_Data_om 
);
always@(posedge CLK or negedge RSTN) begin
	if(~RSTN) begin
		ODST_om <= 0; OMWrite_om <= 0; OMEM_Data_om <= 0;
	end
	else begin
		ODST_om <= ODST_o; OMWrite_om <= OMWrite_o; 
		OMEM_Data_om <= OMEM_Data_o;
	end
end
endmodule
