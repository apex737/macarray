module Control(
	input CLK, RSTN, Start,
	input [11:0] MNT,
	output reg [3:0] ODst, // 0 ~ 15
	output reg [4:0] shI, shW 
);
wire M = MNT[11:8];
wire N = MNT[7:4];
wire T = MNT[3:0];
wire Mbt4 = M > 4;
wire Nbt4 = N > 4;
wire Tbt4 = T > 4;
wire [2:0] MNTCase = { Mbt4, Nbt4, Tbt4};
reg [3:0] m, t;

// State Encoding

reg [2:0] state, next;
always@(posedge CLK or negedge RSTN) begin
	if(~RSTN) state <= IDLE;
	else state <= next;
end

// Next State Logic
reg Acc; // Acc & Store
reg [3:0] MCnt; // MCnt = 0 : IDLE

// t++, m++, cnt4, Xth, mode,..
reg [2:0] n1,n2;
always@* begin
	case(state)
		IDLE:
		INIT: // OutMem = 0; m = 0; t = 0;
		RUN: begin
			// I_shamt, W_shamt 
			if(N > 4) begin
			n1 = t <= 7 ? 4 : N-4;
			n2 = m <= 7 ? 4 : N-4;
			end
			else begin n1 = N; n2 = N; end
			shI = (4'd4-n1) * 4'd8;
			shW = (4'd4-n2) * 4'd8;
			
			// ODst
			if (m >= 4'd4 & m < 4'd8) ODst = t+4'd8;
					else if (m >= 4'd8 & m < 4'd12) ODst = t-4'd8;
					else ODst = t;			
					
			if() begin // 경계값에 도달?
				t = t+1; // I-Pointer
				m = m+1; // W-Pointer
				next = RUN;
			end
			else next = UPDATE;
		end
			
		UPDATE: begin
			
			
		end
		
	endcase
end





// Control Signal
always@* begin
	case(MNTCase)
		3'd0: {Acc, MCnt} = {1'b1, 3'd1};
		3'd1, 3'd4, 3'd5: {Acc, MCnt} = {1'b1, 3'd2};
		3'd2, 3'd3: {Acc, MCnt} = {1'b0, 3'd2};
		3'd6: {Acc, MCnt} = {1'b0, 3'd4};
		3'd7: {Acc, MCnt} = {1'b0, 3'd8};
		default: {Acc, MCnt} = {1'b1, 3'd1};
	endcase
end

endmodule
