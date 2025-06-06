module OBuffer (
    input  wire CLK, RSTN,
    input  wire EN,
    input  wire [15:0] IData,
    output reg  [63:0] Sum64,
    output reg         Valid64
);
	reg [63:0] Prev64;
	reg [63:0] Local64;
	reg [1:0]  cnt;

	wire [15:0] prevSeg = Prev64[ cnt*16 +: 16 ];          
	wire [15:0] addSeg  = prevSeg + IData;                

	always @(posedge CLK or negedge RSTN) begin
			if (~RSTN) begin
					Local64 <= 0; Prev64 <= 0;
					cnt <= 0; Valid64 <= 0;
			end else begin
					Valid64 <= 0;
					if (EN) begin
							Local64 <= {Local64[47:0], addSeg};        
							cnt <= cnt + 2'd1;
							if (cnt == 2'd3) begin
									Sum64   <= {Local64[47:0], addSeg};   
									Valid64 <= 1; // FSM이 RW_O = 1, EN_O = 1로 줘서 Sum64 => WDATA_O로 연결 
									cnt     <= 0;
							end
					end
			end
	end
endmodule
