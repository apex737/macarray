module PE (
    input               CLK, RSTN, EN,
    input               W_LOAD,
    input       signed [7:0]  W_IN,
    input               ENLeft,
    output reg          ENRight,
    input               ENTop,
    output reg          ENDown,
    input       signed [7:0]  A_IN,
    output reg  signed [7:0]  A_OUT,
    input       signed [15:0] PSUM_IN,
    output reg  signed [15:0] PSUM_OUT
);
    reg signed [7:0]  W_reg;
    reg signed [7:0]  A_r1;
    reg signed [15:0] PSUM_r1;
    reg signed [15:0] AxW;
    reg               ENLeft_r1, ENTop_r1;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) W_reg <= 0;
        else if (W_LOAD) W_reg <= W_IN;
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            A_r1 <= 0; PSUM_r1 <= 0; AxW <= 0; ENLeft_r1 <= 0; ENTop_r1 <= 0;
        end else if (EN) begin
            A_r1 <= A_IN; 
						PSUM_r1 <= PSUM_IN; 
						AxW <= A_IN * W_reg;
            ENLeft_r1 <= ENLeft; 
						ENTop_r1 <= ENTop;
        end else begin
            A_r1 <= 0; PSUM_r1 <= 0; AxW <= 0; ENLeft_r1 <= 0; ENTop_r1 <= 0;
        end
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            A_OUT <= 0; PSUM_OUT <= 0; ENRight <= 0; ENDown <= 0;
        end else if (EN) begin
            A_OUT <= A_r1; 
						PSUM_OUT <= PSUM_r1 + AxW;
            ENRight <= ENLeft_r1; 
						ENDown <= ENTop_r1;
        end else begin
            A_OUT <= 0; PSUM_OUT <= 0; ENRight <= 0; ENDown <= 0;
        end
    end
endmodule