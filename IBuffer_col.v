module IBuffer_col (
	input CLK,
	input RSTN,
	input WriteEN,
	input ENDown, 
	input [31:0] IWord,
	output reg [7:0] OD,
	output reg ENShift
);
	reg [7:0] WData [0:3];
	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			WData[0] <= 0; WData[1] <= 0;
			WData[2] <= 0; WData[3] <= 0;
		end
		else begin
			if (WriteEN) begin
				WData[0] <= IWord[31:24];
				WData[1] <= IWord[23:16];
				WData[2] <= IWord[15:8];
				WData[3] <= IWord[7:0];
			end
			else if (ENDown) begin // 역할 1. ENDown은 EN을 아래로 전파한다
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
			ENShift <= 0;
		end 
		else if (ENDown) begin // 역할 2. ENDown은 EN을 옆으로 전파한다
			OD <= WData[0];
			ENShift <= ENDown;
		end
		else begin
			OD <= 0;
			ENShift <= 0;
		end
	end
endmodule