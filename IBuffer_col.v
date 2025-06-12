module IBuffer_col (
	input CLK,
	input RSTN,
	input WriteEN,
	input [1:0] ICOL,
	input ENDown, 
	input [7:0] IWord8,
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
			if (WriteEN) WData[ICOL] <= IWord8;
			else if (ENDown) begin // 역할 1. ENDown은 Load된 IWord를 8bit씩 Shift 시킨다
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
		else if (ENDown) begin 
			OD <= WData[0];		 // 역할 2. ENDown은 Output Data를 아래로 전파한다
			ENShift <= ENDown; // 역할 3. ENDown은 EN을 옆으로 전파한다
		end
		else begin
			OD <= 0;
			ENShift <= 0;
		end
	end
endmodule