module OutputStage (
    input               CLK,
    input               RSTN,
    input               START_CALC,
    input       [63:0]  MAC_ODATA,
    input       [3:0]   MAC_OVALID,
    input       [3:0]   ODST,
    output reg  [63:0]  OMEM_Data,
    output reg  [3:0]   OMEM_Addr,
    output reg          OMEM_Write,
    output reg          Row_Done // '한 행' 작업 완료 신호
);
    reg [15:0] result_buffer [0:3];
    reg [3:0]  odst_reg;
    reg [3:0]  collected_mask;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            collected_mask  <= 4'b0;
            OMEM_Write      <= 1'b0;
            Row_Done        <= 1'b0;
            odst_reg        <= 4'b0;
            result_buffer[0] <= 0; result_buffer[1] <= 0;
            result_buffer[2] <= 0; result_buffer[3] <= 0;
        end else begin
            OMEM_Write <= 1'b0;
            Row_Done   <= 1'b0;

            if (START_CALC) begin
                odst_reg <= ODST;
                collected_mask <= 4'b0;
            end

            if (MAC_OVALID[0]) result_buffer[0] <= MAC_ODATA[63:48];
            if (MAC_OVALID[1]) result_buffer[1] <= MAC_ODATA[47:32];
            if (MAC_OVALID[2]) result_buffer[2] <= MAC_ODATA[31:16];
            if (MAC_OVALID[3]) result_buffer[3] <= MAC_ODATA[15:0];
            
            collected_mask <= collected_mask | MAC_OVALID;

            if (collected_mask == 4'b1111) begin
                OMEM_Write <= 1'b1;
                OMEM_Addr  <= odst_reg;
                OMEM_Data  <= {result_buffer[0], result_buffer[1], result_buffer[2], result_buffer[3]};
                Row_Done   <= 1'b1;
                collected_mask  <= 4'b0;
            end
        end
    end
endmodule
