module IBuffer (
	input CLK, RSTN, CLR,
	input Write, Down, 
	input [31:0] IWord,
	output reg [7:0] OD,
	output reg ENDown,
	output reg ENToss
);

reg [31:0] buffer;
reg [1:0] cnt;
reg active;

always @(posedge CLK or negedge RSTN) begin
	if (~RSTN || CLR) begin
		buffer <= 0; cnt <= 0; active <= 0;
		OD <= 0; ENDown <= 0; ENToss <= 0;
	end
	else begin
		// Write new word
		if (Write) begin
			buffer <= IWord;
			active <= 1;
			cnt <= 0;  // 새로 시작할 때는 초기화
		end
		else if (active) begin // Active output shifting
			case (cnt)
				2'd0: OD <= buffer[31:24];
				2'd1: OD <= buffer[23:16];
				2'd2: OD <= buffer[15:8];
				2'd3: OD <= buffer[7:0];
			endcase

			cnt <= cnt + 1;
			if (cnt == 2'd3) active <= 0;
		end
		else begin
			OD <= 8'b0;  // Idle 시 0 출력
		end

		// Enable 전파
		if (Down) begin
			ENDown <= 1;
			ENToss <= 1;
		end
		else begin
			ENDown <= 0;
			ENToss <= 0;
		end
	end
end

endmodule


