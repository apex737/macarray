module MAC4x4_v2 (
    input               CLK, RSTN, CLR_DP, CLR_W,
    input               W_LOAD,
    input       [1:0]   WROW,
    input       [31:0]  WDATA,
    input       [31:0]  IDATA,
    input       [3:0]   ICOL_VALID,
    output      [63:0]  ODATA,
    output      [3:0]   OVALID
);
    /* 0. Weight Row-Buffer -------------------------------------- */
    reg [31:0] wbank [0:3];
    integer k;
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN)
            for (k=0; k<4; k=k+1) wbank[k] <= 0;
				else if (CLR_W)           
						for(k=0;k<4;k=k+1) wbank[k] <= 0;
        else if (W_LOAD)
            wbank[WROW] <= WDATA;
    end

    /* 1. A / PSUM / Enable PIPE ------------------------------- */
    wire signed [7:0]  a_wires [4:0][3:0];
    wire signed [15:0] psum_wires [3:0][4:0];
    wire        [15:0] en_down_from_pes;
    wire        [15:0] en_right_from_pes;

    genvar r_in,c_in;
		generate 
			for (r_in=0; r_in<4; r_in=r_in+1) begin : A_INIT
					assign a_wires[0][r_in] = IDATA[31-r_in*8 -: 8];
			end
			for (c_in=0; c_in<4; c_in=c_in+1) begin : PSUM_INIT
					assign psum_wires[c_in][0] = 16'd0;
			end
		endgenerate

    /* 2. 4×4 PE ---------------------------------------- */
    genvar i,j;
    generate
        for (i=0; i<4; i=i+1) begin : ROW
            for (j=0; j<4; j=j+1) begin : COL

                wire signed [7:0] w_val =
                    (W_LOAD && (WROW==i)) ? WDATA[31-j*8 -: 8]
                                          : wbank[i][31-j*8 -: 8];

                // ─ Enable 라우팅
                wire en_top  = (i==0) ? ICOL_VALID[j]
                                      : en_down_from_pes[(i-1)*4 + j];
                wire en_left = (j==0) ? en_top
                                      : en_right_from_pes[i*4 + (j-1)];

                PE pe_inst (
                    .CLK    (CLK), .RSTN(RSTN), 
										.CLR_DP (CLR_DP), .CLR_W(CLR_W),
                    .W_LOAD (W_LOAD & (WROW==i)),
                    .W_IN   (w_val),
                    .ENLeft (en_left),  .ENRight(en_right_from_pes[i*4+j]),
                    .ENTop  (en_top),   .ENDown (en_down_from_pes [i*4+j]),
                    .A_IN   (a_wires[i][j]),     .A_OUT (a_wires[i+1][j]),
                    .PSUM_IN(psum_wires[i][j]),  .PSUM_OUT(psum_wires[i][j+1])
                );
            end
        end
    endgenerate

    /* 3. Output ----------------------------------------------------- */
    genvar r_out;
		generate
			for (r_out=0; r_out<4; r_out=r_out+1) begin : OUT_MAP              
					assign ODATA [63-r_out*16 -: 16] = psum_wires[r_out][4];
					assign OVALID[r_out]             = en_right_from_pes[r_out*4+3];
			end
		endgenerate
endmodule


