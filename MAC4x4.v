module MAC4x4 (
    input               CLK, 
    input               RSTN,
    input               W_LOAD,
    input       [1:0]   WROW,
    input       [31:0]  WDATA,
    input       [31:0]  IDATA,
    input       [3:0]   ICOL_VALID,
    output      [63:0]  ODATA,
    output      [3:0]   OVALID
);
		// Note. 
		// a_wire은 en_down_from_pes보다 1행(IData 8bit*4)을 추가로 포함한 경로
		// psum_wires은 en_down_from_pes보다 1열(Input Zeros)을 추가로 포함한 경로
		
    wire signed [7:0]  a_wires [4:0][3:0]; // 8bit(A)의 수직 이동경로
    wire signed [15:0] psum_wires [3:0][4:0]; // 16bit(PSUM)의 수평 이동경로

    wire [15:0]        en_right_from_pes; // PE로부터 우측으로 전달되는 EN 
    wire [15:0]        en_down_from_pes;  // PE로부터 아래로 전달되는 EN

    genvar r_in, c_in, i, j, r_out;
		// a_wires : 최상단의 MAC_ROW 연결 
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
								// 첫번째 행인 경우, IBuffer_col이 준비된 즉시 전달 
                wire en_top_val  = (i == 0) ? ICOL_VALID[j] : en_down_from_pes[(i-1)*4 + j];
								// 첫번째 열인 경우, ENTOP이 Trigger; 
                wire en_left_val = (j == 0) ? en_top_val     : en_right_from_pes[i*4 + (j-1)];
                
                PE pe_inst (
                    .CLK(CLK), .RSTN(RSTN), .EN(1'b1),
                    .W_LOAD(W_LOAD && (WROW == i)), .W_IN(w_val),
                    .ENTop(en_top_val), .ENDown(en_down_from_pes[i*4 + j]),
                    .ENLeft(en_left_val), .ENRight(en_right_from_pes[i*4 + j]),
                    .A_IN(a_wires[i][j]), .A_OUT(a_wires[i+1][j]),
                    .PSUM_IN(psum_wires[i][j]), .PSUM_OUT(psum_wires[i][j+1])
                );
            end
        end
    endgenerate

    for (r_out = 0; r_out < 4; r_out = r_out + 1) begin
        assign ODATA[ (63 - r_out*16) -: 16 ] = psum_wires[r_out][4]; // 64비트 데이터 버스 연결
        assign OVALID[r_out] = en_right_from_pes[r_out*4 + 3]; // OVALID 신호 연결
    end
endmodule