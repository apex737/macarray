module IBuffer (
	input CLK, RSTN, EN,
	input [31:0] IWord,
	output reg [7:0] OData,
	output reg ENDown, ENRight
);

reg [31:0] IBuffer;
reg [3:0] ENReg; // enable pipeline

wire active = |ENReg; // 하나라도 1이면 active

always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) begin 
		IBuffer <= 0;
		ENReg   <= 0;
		OData   <= 0;
		ENRight <= 0;
		ENDown  <= 0;
	end
	else begin
		if (EN) begin
			IBuffer <= IWord;
			ENReg   <= 4'b1111;  // 4-Bullets
		end 
		else if (active) begin
			IBuffer <= {IBuffer[23:0], 8'b0};     // Shift left
			ENReg   <= {ENReg[2:0], 1'b0};        // Enable pipeline shift
		end

		OData   <= IBuffer[31:24];
		ENRight <= EN;  // FSM에서 MAC_EX를 유지하는 한, 1로 유지됨 
		ENDown  <= ENReg[3];
	end
end

endmodule
