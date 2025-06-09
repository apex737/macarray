module MAC4x4 (
    input               CLK, 
    input               RSTN,
    input               W_LOAD,
    input       [1:0]   WROW,
    input       [31:0]  WDATA,
    input       [31:0]  IDATA,
    input       [3:0]   ICOL_VALID, // 각 Col에서 내려오는 EN
    output      [63:0]  ODATA,
    output      [3:0]   OVALID
);
		
		// a_wire은 en_down_from_pes에서 최상단 1행(IROW_o 32bit)을 추가로 포함한 경로
		wire signed [7:0]  a_wires [4:0][3:0];  // 8bit(A)의 수직 이동경로
		wire [15:0] en_down_from_pes;  // "PE로부터" 아래로 전파되는 EN

		// psum_wires은 en_right_from_pes에서 최좌측 1열(Input Zeros)을 추가로 포함한 경로
    wire signed [15:0] psum_wires [3:0][4:0];  // 16bit(PSUM)의 수평 이동경로
		wire [15:0] en_right_from_pes; // "PE로부터" 우측으로 전파되는 EN 


    genvar r_in, c_in, i, j, r_out;
		// IROW_o (IBuffer4) -> IDATA 로 직접 연결 
    for (r_in = 0; r_in < 4; r_in = r_in + 1) begin 
        assign a_wires[0][r_in] = IDATA[ (31 - r_in*8) -: 8 ];
    end
		// 최좌측에서 들어오는 c_in은 전부 0
    for (c_in = 0; c_in < 4; c_in = c_in + 1) begin
        assign psum_wires[c_in][0] = 16'b0;
    end

    generate
			for (i = 0; i < 4; i = i + 1) begin: ROW
				for (j = 0; j < 4; j = j + 1) begin: COL
						
						wire signed [7:0] w_val = WDATA[ (31 - j*8) -: 8 ];
						// 첫번째 행 (i = 0)
						// ICOL_VALID가 ENTOP (수직 Enable Input) 결정; 나머지는 ENDown이 결정
						wire en_top_val  = (i == 0) ? ICOL_VALID[j] : en_down_from_pes[(i-1)*4 + j];
						// 첫번째 열 (j = 0) 
						// ENTOP이 ENLeft (수평 Enable Input) 결정; 나머지는 ENRight가 결정
						wire en_left_val = (j == 0) ? en_top_val     : en_right_from_pes[i*4 + (j-1)];
						
						PE pe_inst (
								.CLK(CLK), .RSTN(RSTN), .EN(1'b1),
								.W_LOAD(W_LOAD && (WROW == i)), 
								.W_IN(w_val),
								.ENTop(en_top_val), // INPUT
								.ENDown(en_down_from_pes[i*4 + j]), // OUTPUT
								.ENLeft(en_left_val), // INPUT
								.ENRight(en_right_from_pes[i*4 + j]), // OUTPUT
								.A_IN(a_wires[i][j]), 
								.A_OUT(a_wires[i+1][j]),
								.PSUM_IN(psum_wires[i][j]), 
								.PSUM_OUT(psum_wires[i][j+1])
						);
				end
			end
    endgenerate

    for (r_out = 0; r_out < 4; r_out = r_out + 1) begin
        assign ODATA[ (63 - r_out*16) -: 16 ] = psum_wires[r_out][4]; // 64비트 데이터 버스 연결
        assign OVALID[r_out] = en_right_from_pes[r_out*4 + 3]; // OVALID[0] : OBuffer 0행 Valid
    end
endmodule
