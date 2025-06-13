/*
    SINGLE-PORT SYNCHRONOUS MEMORY MODEL

    FUNCTION TABLE:

    CLK        CSN      WEN      A        DI       DOUT        COMMENT
    ======================================================================
    posedge    H        X        X        X        DOUT(t-1)   DESELECTED
    posedge    L        L        VALID    VALID    DOUT(t-1)   WRITE CYCLE
    posedge    L        H        VALID    X        MEM(A)      READ CYCLE

    USAGE:

    SRAM    #(.BW(32), .AW(10), .ENTRY(1024)) InstMemory (
                    .CLK    (CLK),
                    .CSN    (1'b0),
                    .A      (),
                    .WEN    (),
                    .DI     (),
                    .DOUT   ()
    );
*/

module SRAM #(parameter BW = 32, AW = 4, ENTRY = 16, WRITE = 0, MEM_FILE="mem.hex") (
    input    wire                CLK,
    input    wire                CSN,    // CHIP SELECT (ACTIVE LOW)
    input    wire    [AW-1:0]    A,      // ADDRESS
    input    wire                WEN,    // READ/WRITE ENABLE
    input    wire    [BW-1:0]    DI,     // DATA INPUT (O - MEM)
    output   wire    [BW-1:0]    DOUT    // DATA OUTPUT (I/W - MEM)
);

    parameter    ATIME    = 2;

    reg        [BW-1:0]    ram[0:ENTRY-1]; // ram 그대로 활용
    reg        [BW-1:0]    outline;
	reg		   [63:0]	   readmem_inst[0:7]; // 64Byte * 8줄 
	
	integer i;
	
    initial begin
	    if(WRITE>0)
		    $readmemh(MEM_FILE, readmem_inst);
			for (i=0; i<16; i=i+1) begin
				if (i<8)
					ram[i] = readmem_inst[i][63:32];
				else
					ram[i] = readmem_inst[i-8][31:0];
			end
    end

    always @ (posedge CLK)
    begin
        if (~CSN)
        begin
            if (WEN)    outline    <= ram[A]; // read
            else        ram[A]    <= DI; // write
        end
    end

    assign    #(ATIME)    DOUT    = outline;

endmodule
