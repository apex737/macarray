module PE (
    input               CLK, 
    input               RSTN, 
    input               EN,
    // Weight Input
    input               W_LOAD,
    input       signed [7:0]  W_IN,
    // Enable Paths
    input               ENLeft,
    output reg          ENRight,
    input               ENTop,
    output reg          ENDown,
    // Data Paths
    input       signed [7:0]  A_IN, // from top
    output      signed [7:0]  A_OUT, // to bottom
    input       signed [15:0] PSUM_IN, // from left
    output      signed [15:0] PSUM_OUT // to right
);

    reg signed [7:0]  W_reg;
    reg signed [7:0]  A_reg;
    reg signed [15:0] Psum_reg;

    // Weight Load Logic
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) W_reg <= 0;
        else if (W_LOAD) W_reg <= W_IN;
    end

    // Datapath & Enable-path Logic
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            A_reg    <= 0;
            Psum_reg <= 0;
            ENRight  <= 0;
            ENDown   <= 0;
        end 
        else if (EN) begin
            A_reg    <= A_IN;
            Psum_reg <= PSUM_IN + (A_IN * W_reg);
            ENRight  <= ENLeft;  // Propagate horizontal enable
            ENDown   <= ENTop;   // Propagate vertical enable
        end 
        else begin
            A_reg    <= 0;
            Psum_reg <= 0;
            ENRight  <= 0;
            ENDown   <= 0;
        end
    end

    assign A_OUT    = A_reg;
    assign PSUM_OUT = Psum_reg;

endmodule