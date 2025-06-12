// ────────────────────────────────────────────────────────────────
//  PE : PSUM 누산 타이밍만 다시 정리 (else-if → 두 단계 if문)
// ────────────────────────────────────────────────────────────────
module PE (
    input               CLK, RSTN, CLR_DP, CLR_W,
    input               W_LOAD,
    input       signed [7:0]  W_IN,
    input               ENLeft,  output reg ENRight,
    input               ENTop,   output reg ENDown,
    input       signed [7:0]  A_IN,
    output reg  signed [7:0]  A_OUT,
    input       signed [15:0] PSUM_IN,
    output reg  signed [15:0] PSUM_OUT
);
    reg signed [7:0]  W_reg;

    always @(posedge CLK or negedge RSTN)
        if (!RSTN)     	 W_reg <= 0;
				else if (CLR_W)  W_reg <= 0;
        else if (W_LOAD) W_reg <= W_IN;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            {A_OUT, PSUM_OUT} <= 0;
            {ENRight, ENDown} <= 0;
				end
				else if (CLR_DP) begin
						{A_OUT, PSUM_OUT} <= 0;
            {ENRight, ENDown} <= 0;
        end
        else if (ENLeft | ENTop) begin
            A_OUT   <= A_IN;               // A 데이터 전달
            ENRight <= ENLeft;             // Enable 전달 (→)
            ENDown  <= ENTop;              // Enable 전달 (↓)
            if (ENLeft & ENTop)            // 두 Enable 모두 들어올 때만 MAC
                PSUM_OUT <= A_IN * W_reg + PSUM_IN;
        end
    end
endmodule
