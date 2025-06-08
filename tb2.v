`timescale 1ns/1ps

module tb_final_system_v2;

    // Parameters & Signals
    localparam CLK_PERIOD = 10;
    reg CLK, RSTN;
    integer i;

    // Control signals from Testbench
    reg         LOAD_EN;
    reg         START_CALC;
    reg [1:0]   IDST;
    reg [31:0]  IWord;
    reg         W_LOAD;
    reg [1:0]   WROW;
    reg [31:0]  WDATA;
    
    // Wires for connecting modules
    wire [31:0] IROW_o;
    wire [3:0]  ICOL_VALID_o;
    wire [63:0] ODATA;
    wire [3:0]  OVALID;

    // Instantiation
    IBuffer4 uut_ibuffer (
        .CLK(CLK), .RSTN(RSTN), .LOAD_EN(LOAD_EN), .START_CALC(START_CALC),
        .IDST(IDST), .IWord(IWord), .IROW_o(IROW_o), .ICOL_VALID(ICOL_VALID_o),
        .ODST_i(4'b0), .ODST_o()
    );

    MAC4x4 uut_mac (
        .CLK(CLK), .RSTN(RSTN), .W_LOAD(W_LOAD), .WROW(WROW), .WDATA(WDATA),
        .IDATA(IROW_o), .ICOL_VALID(ICOL_VALID_o), .ODATA(ODATA), .OVALID(OVALID)
    );

    // Clock Generator
    initial begin
        CLK = 0;
        forever #(CLK_PERIOD/2) CLK = ~CLK;
    end

    // Test Sequence
    initial begin
        $display("=========================================");
        $display("   Final System Testbench (v2) Started   ");
        $display("=========================================");

        // 1. Reset
        RSTN=0; LOAD_EN=0; START_CALC=0; IDST=0; IWord=0; W_LOAD=0; WROW=0; WDATA=0;
        #20; RSTN = 1'b1;
        $display("[%0t] System Reset Released.", $time);

        // 2. Load Weights into MAC4x4
        W_LOAD=1; WDATA=32'h01010101;
        for (i=0; i<4; i=i+1) begin @(posedge CLK); WROW=i; end
        @(posedge CLK); W_LOAD=0;
        $display("--- Weight Loading Finished ---");

        // 3. Load Input Matrix into IBuffer4
        $display("--- Input Loading Phase ---");
        LOAD_EN = 1'b1; // 로드 신호만 활성화
        START_CALC = 1'b0; // 계산 시작 신호는 비활성화
        IDST=0; IWord={8'd2,8'd1,8'd2,8'd1}; @(posedge CLK);
        IDST=1; IWord={8'd1,8'd2,8'd1,8'd2}; @(posedge CLK);
        IDST=2; IWord={8'd2,8'd1,8'd2,8'd1}; @(posedge CLK);
        IDST=3; IWord={8'd1,8'd2,8'd1,8'd2}; @(posedge CLK);
        @(posedge CLK); LOAD_EN = 1'b0; // 로드 종료
        $display("--- Input Loading Finished ---");

        // 4. Start Computation
        @(posedge CLK);
        START_CALC = 1'b1; // 계산 시작 신호를 1 사이클만 펄스로 인가
        $display("[%0t] START_CALC pulsed. Computation begins.", $time);
        @(posedge CLK);
        START_CALC = 1'b0;
        
        // 5. Monitor & Finish
        $display("\n--- Monitoring System Flow ---");
        $monitor("Time=%0t | ICOL_V=%b | IROW(to MAC)=%h | OVALID=%b | ODATA=%h", $time, ICOL_VALID_o, IROW_o, OVALID, ODATA);
        
        #300;
        $finish;
    end
endmodule