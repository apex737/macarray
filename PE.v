module PE(
	input CLK, RSTN, Load,
	input signed [7:0] weight,
	// Enable
	input ENLeft, ENTop,                 
	output reg ENDown, ENRight,
	// top -> down
	input signed [7:0] ITop,
	output reg signed [7:0] ODown,
	// left -> right
	input signed [15:0] psumLeft,
	output reg signed [15:0] psumRight
);

reg signed [7:0] W;
reg signed [7:0] ITop_r;
reg signed [15:0] IxW, ACC;

// enable pipeline
reg ENTop_r;
reg EN_r0, EN_r1, EN_r2;

// weight stationary load
always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) W <= 0;
	else if (Load) W <= weight;
end

// Stage1 : Store Input 
always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) begin
		ITop_r <= 0;
		ENTop_r <= 0;
		EN_r0 <= 0;
	end
	else if (ENTop) begin
		ITop_r <= ITop;
		ENTop_r <= ENTop;
		EN_r0 <= ENLeft;
	end
end

// Stage2 : MUL 
always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) begin IxW <= 0; ODown <= 0; ENDown <= 0; end
	else if (EN_r0) begin 
		IxW <= ITop_r * W; 
		ODown <= ITop_r; 
		ENDown <= ENTop_r;
		EN_r1 <= EN_r0;
	end
end

// Stage3 : ACC 
always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) begin psumRight <= 0; ENRight <= 0; end
	else if (EN_r1) begin
		ACC <= IxW + psumLeft;
		EN_r2 <= EN_r1;
	end
end

// Stage4 : Pass Right ~~~> Next MAC Stage1
always @(posedge CLK or negedge RSTN) begin
	if (~RSTN) begin psumRight <= 0; ENRight <= 0; end
	else if (EN_r2) begin
		psumRight <= ACC;
		ENRight <= EN_r2;
	end
end

endmodule


