module IBuffer_col (
	input CLK,
	input RSTN,
	input WriteEN, // 버퍼에 들어온 값을 실제로 쓸 것인지 결정
	input ShiftEN, // en을 인접 버퍼로 전파 
	input [31:0] IWord, // IBuffer4에서 전달받은 값 
	output reg [7:0] OD,
	output reg ShiftEN_o
);
	reg [7:0] WData [0:3];

	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			WData[0] <= 0; WData[1] <= 0;
			WData[2] <= 0; WData[3] <= 0;
		end
		else begin
			if (WriteEN) begin
				WData[3] <= IWord[7:0];
				WData[2] <= IWord[15:8];
				WData[1] <= IWord[23:16];
				WData[0] <= IWord[31:24];
			end
			else if (ShiftEN) begin // Write Mode와 Run Mode를 분리
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