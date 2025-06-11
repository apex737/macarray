// macarray에 정의

module ACC64(
	input ACC, 
	input [3:0] ODST_i,
	input [63:0] Mem64, Out64
	output [3:0] ODST_o,
	output [63:0] Acc64
);
// Out64 = ACC ? Load64 : 0;
endmodule
