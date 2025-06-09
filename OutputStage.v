module OutputStage (
    input               CLK,
    input               RSTN,
    input       [63:0]  MAC_ODATA,       // 16-bit×4 한 번에 들어옴
    input       [3:0]   MAC_OVALID,      // N-클럭 유지 (누적형) Valid
    input       [3:0]   ODST_i,            // 타일 기준 주소

    output reg  [63:0]  OMEM_Data,
    output reg  [3:0]   ODST_o,       
    output reg          OMEM_Write,
    output reg          Tile_Done
);
    // ───────── 행별 버퍼 / 카운터 ─────────
    reg [63:0] row_buf [0:3];        // 누적 64-bit
    reg  [1:0] seg_cnt [0:3];        // 행 별 카운터
    reg  [3:0] done_mask;            // 행 별 완료 신호
    reg  [3:0] ODST_r;

    wire [15:0] seg [0:3];
    assign seg[0] = MAC_ODATA[63:48];
    assign seg[1] = MAC_ODATA[47:32];
    assign seg[2] = MAC_ODATA[31:16];
    assign seg[3] = MAC_ODATA[15:0];

    integer i;

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            // 초기화
            OMEM_Write  <= 1'b0;
            Tile_Done   <= 1'b0;
            done_mask   <= 4'b0;
            for (i=0;i<4;i=i+1) begin
                row_buf[i] <= 64'b0;
                seg_cnt[i] <= 2'd0;
            end
        end 
				else begin
            OMEM_Write <= 1'b0;
            Tile_Done  <= 1'b0;

            // 1) 유효 행마다 16-bit 시프트·누적
            for (i=0;i<4;i=i+1) begin
                if (MAC_OVALID[i] && !done_mask[i]) begin
                    row_buf[i] <= (row_buf[i] << 16) | {48'b0, seg[i]}; // 16bit Shift, 새로 들어온 16bit을 push
                    seg_cnt[i] <= seg_cnt[i] + 1'b1;
                end
            end

            // 2) 4번째 세그먼트 누적 완료 → 메모리 Write
            for (i=0;i<4;i=i+1) begin
                if (MAC_OVALID[i] &&
                    (seg_cnt[i] == 2'd3) &&   // 이번 cycle이 4번째 세그
                    !done_mask[i]) begin

                    OMEM_Write <= 1'b1;
                    OMEM_Data  <= (row_buf[i] << 16) | seg[i]; // 갓 완성된 64-bit

                    ODST_o  <= ODST_r;

                    done_mask[i] <= 1'b1;      // 이 행 완료 플래그
                end
            end

            // 3) 타일 완료 (4행 모두 write 끝)
            if (OMEM_Write && (&done_mask))   // 마지막 행 write 직후
                Tile_Done <= 1'b1;
        end
    end
endmodule

