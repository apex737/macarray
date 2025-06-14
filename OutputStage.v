module OutputStage (
    input               CLK,
    input               RSTN,
    input               CLR_DP,
		input 			[2:0] 	ROW_TOTAL,
    input       [63:0]  MAC_ODATA,   // 16‑bit ×4 (row‑vector)
    input       [3:0]   MAC_OVALID,  // per‑row valid
    input       [3:0]   ODST_i,      // tile‑base dst address
    input       [1:0]   ICOL,        // column index 0..3
    input               Load_EN, 			

    output reg  [63:0]  OMEM_Data, // WDATA
    output reg  [3:0]   ODST_o,		 // ADDR_O
    output reg          OMWrite_o, // 
    output reg          Tile_Done
);
    // ───────── 내부 버퍼 ─────────────────────────────────────
    reg  [63:0] row_buf [0:3];
    reg  [1:0]  seg_cnt [0:3];
    reg  [3:0]  done_mask;
    reg  [3:0]  ODST_r   [0:3];   // column‑wise 주소

    // seg[i] : 이번 사이클 각 행이 받아야 할 16‑bit 조각
    wire [15:0] seg [0:3];
    assign seg[0] = MAC_ODATA[63:48];
    assign seg[1] = MAC_ODATA[47:32];
    assign seg[2] = MAC_ODATA[31:16];
    assign seg[3] = MAC_ODATA[15:0];

    // ───────── write‑phase FSM ───────────────────────────────
    reg        Write;       // 0 = STORE, 1 = WRITE
    reg [1:0]  idx;       // 0 → 1 → 2 → 3

    integer i;
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            for (i = 0; i < 4; i = i + 1) ODST_r[i] <= 0;
        end
        else if (Tile_Done) begin
            for (i = 0; i < 4; i = i + 1) ODST_r[i] <= 0;
        end
        else if (Load_EN) begin
            ODST_r[ICOL] <= ODST_i;
        end
    end

    // ───────── 메인 로직 ────────────────────────────────────
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            Write  <= 1'b0;
            idx  <= 2'd0;
            OMWrite_o    <= 1'b0; 
            Tile_Done    <= 1'b0;
            done_mask    <= 4'b0;
            for (i = 0; i < 4; i = i + 1) begin
                row_buf[i] <= 64'b0;
                seg_cnt[i] <= 2'd0;
            end
        end 
				else if (CLR_DP) begin
					Write  <= 1'b0;
            idx  <= 2'd0;
            OMWrite_o    <= 1'b0; 
            Tile_Done    <= 1'b0;
            done_mask    <= 4'b0;
            for (i = 0; i < 4; i = i + 1) begin
                row_buf[i] <= 64'b0;
                seg_cnt[i] <= 2'd0;
            end
				end
				else begin
            OMWrite_o <= 1'b0;   // 기본값
            Tile_Done <= 1'b0;

            // ───── STORE 단계 (행별 seg 수집) ─────────────
            if (!Write) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (MAC_OVALID[i] && !done_mask[i]) begin
                        row_buf[i] <= (row_buf[i] << 16) | {48'b0, seg[i]};
                        seg_cnt[i] <= seg_cnt[i] + 1'b1;
                        if (seg_cnt[i] == 2'd3)
                            done_mask[i] <= 1'b1;   // row i 완료
                    end
                end
                // 4×4 full → WRITE 단계 진입
                if (done_mask == 4'b1111) begin
                    Write <= 1'b1;
                    idx <= 2'd0;
                end
            end
            // ───── WRITE 단계 (열 묶음 64‑bit 출력) ─────────
            else begin
                OMWrite_o <= 1'b1;
                ODST_o    <= ODST_r[idx];

                // column‑wise 패킹
                case (idx)
                    2'd0: OMEM_Data <= { row_buf[0][63:48], row_buf[1][63:48], row_buf[2][63:48], row_buf[3][63:48] };
                    2'd1: OMEM_Data <= { row_buf[0][47:32], row_buf[1][47:32], row_buf[2][47:32], row_buf[3][47:32] };
                    2'd2: OMEM_Data <= { row_buf[0][31:16], row_buf[1][31:16], row_buf[2][31:16], row_buf[3][31:16] };
                    2'd3: OMEM_Data <= { row_buf[0][15 :0 ], row_buf[1][15 :0 ], row_buf[2][15 :0 ], row_buf[3][15 :0 ] };
                endcase

                // 다음 열로
                if (idx == ROW_TOTAL - 1) begin
                    Tile_Done   <= 1'b1;            // 마지막 열
                    Write <= 1'b0;            // STORE 로 복귀
                    idx <= 2'd0;
                    done_mask   <= 4'b0;
                    for (i = 0; i < 4; i = i + 1) begin
                        row_buf[i] <= 64'b0;
                        seg_cnt[i] <= 2'd0;
                    end
                end else begin
                    idx <= idx + 1'b1;
                end
            end
        end
    end
endmodule
