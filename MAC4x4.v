// 파일명: MAC4x4.v
module MAC4x4 (
    input               CLK, 
    input               RSTN,
		// [입력 1] 가중치 인터페이스
    input               W_LOAD,
    input       [1:0]   WROW,
    input       [31:0]  WDATA,
		// [입력 2] 입력 데이터 및 제어 인터페이스
    input       [31:0]  IDATA,
    input       [3:0]   ICOL_VALID,
		// [출력] 결과 데이터 및 제어 인터페이스
    output      [63:0]  ODATA,
    output      [3:0]   OVALID
);
    wire signed [7:0]  a_wires [4:0][3:0]; // 8bit(A)의 수직 이동경로
    wire signed [15:0] psum_wires [3:0][4:0]; // 16bit(PSUM)의 수평 이동경로
    wire [15:0]        en_right_from_pes;
    wire [15:0]        en_down_from_pes;

    genvar r_in, c_in, i, j, r_out;

    for (r_in = 0; r_in < 4; r_in = r_in + 1) begin
        assign a_wires[0][r_in] = IDATA[ (r_in*8+7) -: 8 ];
    end

    for (c_in = 0; c_in < 4; c_in = c_in + 1) begin
        assign psum_wires[c_in][0] = 16'b0;
    end

    generate
        for (i = 0; i < 4; i = i + 1) begin: ROW
            for (j = 0; j < 4; j = j + 1) begin: COL
                
                wire signed [7:0] w_val = WDATA[ (j*8+7) -: 8 ];

                wire en_top_val  = (i == 0) ? ICOL_VALID[j] : en_down_from_pes[(i-1)*4 + j];
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
        assign ODATA[ (r_out*16+15) -: 16 ] = psum_wires[r_out][4];
        assign OVALID[r_out] = en_right_from_pes[r_out*4 + 3];
    end
endmodule
