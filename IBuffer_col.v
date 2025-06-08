module IBuffer_col (
	input CLK,
	input RSTN,
	input WriteEN,
	input ShiftEN,
	input [31:0] IWord,
	output reg [7:0] OD,
	output reg ShiftEN_o
);
	reg [7:0] WData [0:3];
	integer i;

	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			for (i = 0; i < 4; i = i + 1) begin
				WData[i] <= 0;
			end
		end
		else begin
			if (WriteEN) begin
				WData[3] <= IWord[7:0];
				WData[2] <= IWord[15:8];
				WData[1] <= IWord[23:16];
				WData[0] <= IWord[31:24];
			end
			else if (ShiftEN) begin
				WData[0] <= WData[1];
				WData[1] <= WData[2];
				WData[2] <= WData[3];
				WData[3] <= 8'b0;
			end
		end
	end

	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			OD <= 0;
			ShiftEN_o <= 0;
		end 
		else begin
			OD <= WData[0];
			ShiftEN_o <= ShiftEN;
		end
	end
endmodule