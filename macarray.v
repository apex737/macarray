/*****************************************
    
    Team 17 : 
        2020110401    이시형
        2024000001    Lee Minho
*****************************************/
////////////////////////////////////
//  TOP MODULE
////////////////////////////////////
module macarray (
	input CLK, RSTN, START,
	input	[11:0] MNT,
	// INPUT DATA
	input [31:0] RDATA_I,
	input [31:0] RDATA_W,
	input [63:0] RDATA_O,
	// OUTPUT I/WMEM
	output EN_I, EN_W, 
	output [3:0] ADDR_I, ADDR_W, 
	// OUTPUT OMEM
	output EN_O, RW_O,
	output [3:0] ADDR_O,
	output [63:0] WDATA_O
);

	
//////////////////////////////////////////////////////////////////////
//  CONTROL
//////////////////////////////////////////////////////////////////////
wire ACC_ctrl, START_CALC_ctrl;
wire [1:0] ICOL_ctrl, WROW_ctrl;
wire [3:0] ODST_ctrl;
wire [4:0] shamt_ctrl;
wire ILoad_ctrl, WLoad_ctrl;
wire Tile_Done_o;

Control u_ctrl(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), .Start(START), .Tile_Done(Tile_Done_o), 
	.MNT(MNT), 
	// OUTPUT
	.ADDR_I(ADDR_I), .ADDR_W(ADDR_W), // INTERFACE OUTPUT
	.LOAD_I(ILoad_ctrl), .LOAD_W(WLoad_ctrl), 
	.START_CALC(START_CALC_ctrl), .ACC(ACC_ctrl), .shamt(shamt_ctrl),   
	.ICOL(ICOL_ctrl), .WROW(WROW_ctrl), .ODST(ODST_ctrl)
);
assign EN_I = ILoad_ctrl;
assign EN_W = WLoad_ctrl;

//////////////////////////////////////////////////////////////////////
//  DATAPATH
//////////////////////////////////////////////////////////////////////

wire START_CALC_mb, ILoad_mb, WLoad_mb;
wire [1:0] ICOL_mb, WROW_mb;
wire [3:0] ODST_mb;
wire [4:0] shamt_mb;

MemBuffer u_mb(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), .START_CALC0(START_CALC_ctrl),
	.ILoad0(ILoad_ctrl), .WLoad0(WLoad_ctrl), 
	.shamt0(shamt_ctrl), .ICOL0(ICOL_ctrl), .WROW0(WROW_ctrl), .ODST0(ODST_ctrl),
	// OUTPUT
	.START_CALC1(START_CALC_mb), .ILoad1(ILoad_mb), .WLoad1(WLoad_mb), 
	.shamt1(shamt_mb), .ICOL1(ICOL_mb),
	.WROW1(WROW_mb), .ODST1(ODST_mb)
);

wire START_CALC_im, ILoad_im;
wire [1:0] ICOL_im;
wire [3:0] ODST_im;
wire [4:0] shamt_im;
wire [31:0] IDATA_im;
wire [31:0] IShifted = IDATA_im << shamt_im;
IMBuffer u_im(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), 
	.IDATA1(RDATA_I),  // INTERFACE INPUT
	.START_CALC1(START_CALC_mb), .ILoad1(ILoad_mb),
	.shamt1(shamt_mb), .ICOL1(ICOL_mb), .ODST1(ODST_mb), 
	// OUTPUT
	.IDATA2(IDATA_im), .START_CALC2(START_CALC_im), .shamt2(shamt_im), 
	.ICOL2(ICOL_im), .ODST2(ODST_im), .ILoad2(ILoad_im)
);

wire WLoad_wm;
wire [31:0] WDATA_wm;
wire [4:0] shamt_wm;
wire [1:0] WROW_wm;
wire [31:0] WShifted = WDATA_wm << shamt_wm;

WMBuffer u_wm (
	 // INPUT
	.CLK(CLK), .RSTN(RSTN), .WLoad1(WLoad_mb),
	.WDATA1(RDATA_W),  // INTERFACE INPUT
	.shamt1(shamt_mb), .WROW1(WROW_mb),
	// OUTPUT
	.WDATA2(WDATA_wm), .shamt2(shamt_wm), 
	.WLoad2(WLoad_wm), .WROW2(WROW_wm)
);

wire [3:0] ICOL_VALID_ib;
wire [3:0] ODST_ib;
wire [31:0] IROW_ib;
IBuffer4 u_ib4(
	// INPUT
  .CLK(CLK), .RSTN(RSTN), 
	.LOAD_EN(ILoad_im), 
	.START_CALC(START_CALC_im),
	.IWord(IShifted), // Valid INPUT_I
	.ICOL(ICOL_im), 
	.ODST_i(ODST_im),
	// OUTPUT
	.IROW_o(IROW_ib), .ICOL_VALID(ICOL_VALID_ib), .ODST_o(ODST_ib)
);

wire [63:0] ODATA_mac;
wire [3:0] OVALID_mac;
MAC4x4_v2 u_mac4x4(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), 
	.W_LOAD(WLoad_wm), 
	.WROW(WROW_wm), 
	.WDATA(WShifted), // Valid INPUT_W
	.IDATA(IROW_ib), .ICOL_VALID(ICOL_VALID_ib), 
	// OUTPUT
	.ODATA(ODATA_mac), .OVALID(OVALID_mac)  
);

wire [63:0] OMEM_Data_o;
wire [3:0] ODST_o;
wire OMEM_Write_o;
OutputStage u_outputStage(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), .MAC_ODATA(ODATA_mac),
	.MAC_OVALID(OVALID_mac), .ODST_i(ODST_ib), 
	// OUTPUT
	.OMEM_Data(OMEM_Data_o), .ODST_o(ODST_o),
	.OMEM_Write(OMEM_Write_o), .Tile_Done(Tile_Done_o)          
);


endmodule
