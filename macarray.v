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
	// OUTPUT I/WMEM
	output EN_I, EN_W, 
	output [3:0] ADDR_I, ADDR_W, 
	// OMEM
	input [63:0] RDATA_O,
	output reg EN_O, RW_O,
	output reg [3:0] ADDR_O,
	output reg [63:0] WDATA_O
);

	
//////////////////////////////////////////////////////////////////////
//  CONTROL
//////////////////////////////////////////////////////////////////////
wire ACC_ctrl, START_CALC_ctrl;
wire [1:0] ICOL_ctrl, WROW_ctrl;
wire [2:0] ROW_TOTAL_ctrl;
wire [3:0] ODST_ctrl;
wire [4:0] shamt_ctrl;
wire ILoad_ctrl, WLoad_ctrl;
wire CLR_DP_ctrl, CLR_W_ctrl;
wire Tile_Done_o;
wire LOAD_DONE, STORE_DONE, INIT_DONE;

Control_v2 u_ctrl(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), .Start(START), .Tile_Done(Tile_Done_o), 
	.MNT(MNT), .LOAD_DONE(LOAD_DONE), .STORE_DONE(STORE_DONE), .INIT_DONE(INIT_DONE),
	// OUTPUT
	.ADDR_I(ADDR_I), .ADDR_W(ADDR_W), // INTERFACE OUTPUT
	.LOAD_I(ILoad_ctrl), .LOAD_W(WLoad_ctrl), .START_CALC(START_CALC_ctrl), 
	.ACC(ACC_ctrl), .OMSRC(OMSRC), .shamt(shamt_ctrl),   
	.ICOL(ICOL_ctrl), .WROW(WROW_ctrl), .ODST(ODST_ctrl),
	.CLR_DP(CLR_DP_ctrl), .CLR_W(CLR_W_ctrl), .ROW_TOTAL(ROW_TOTAL_ctrl)
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
wire [1:0] ICOL_ib;
wire [31:0] IROW_ib;
wire LOAD_EN_ib;
IBuffer4 u_ib4(
	// INPUT
  .CLK(CLK), .RSTN(RSTN), 
	.LOAD_EN(ILoad_im), 
	.START_CALC(START_CALC_im),
	.IWord(IShifted), // Valid INPUT_I
	.ICOL_i(ICOL_im), 
	.ODST_i(ODST_im),
	// OUTPUT
	.IROW_o(IROW_ib), .ICOL_VALID(ICOL_VALID_ib), 
	.ODST_o(ODST_ib), .ICOL_o(ICOL_ib), .LOAD_EN_o(LOAD_EN_ib)
);

wire [63:0] ODATA_mac;
wire [3:0] OVALID_mac;
MAC4x4_v2 u_mac4x4(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), 
	.CLR_W(CLR_W_ctrl), .CLR_DP(CLR_DP_ctrl),
	.W_LOAD(WLoad_wm), 
	.WROW(WROW_wm), 
	.WDATA(WShifted), // Valid INPUT_W
	.IDATA(IROW_ib), .ICOL_VALID(ICOL_VALID_ib), 
	// OUTPUT
	.ODATA(ODATA_mac), .OVALID(OVALID_mac)  
);

wire [63:0] OMEM_Data_o;
wire [3:0] ODST_o;
wire OMWrite_o;
OutputStage u_outputStage(
	// INPUT
	.CLK(CLK), .RSTN(RSTN), .CLR_DP(CLR_DP_ctrl), .ROW_TOTAL(ROW_TOTAL_ctrl),
	.MAC_ODATA(ODATA_mac), .MAC_OVALID(OVALID_mac), 
	.ODST_i(ODST_ib), .ICOL(ICOL_ib),
	.Load_EN(LOAD_EN_ib), 
	// OUTPUT
	.OMEM_Data(OMEM_Data_o), .ODST_o(ODST_o),
	.OMWrite_o(OMWrite_o), .Tile_Done(Tile_Done_o)          
);

wire OMWrite_om;
wire [63:0] OMEM_Data_om;
wire [3:0] ODST_om;

OMBuffer u_om(
	// INPUT
	.CLK(CLK), .RSTN(RSTN),	.ODST_o(ODST_o),
	.OMWrite_o(OMWrite_o), .OMEM_Data_o(OMEM_Data_o),
	// OUTPUT
	.ODST_om(ODST_om), .OMWrite_om(OMWrite_om),
	.OMEM_Data_om(OMEM_Data_om)
);

wire EN_wb; 
wire OMWrite_wb;
wire [63:0] WData_wb;
wire [3:0] ODST_wb;

wire signed [15:0] seg0 = $signed(OMEM_Data_om[15:0])   + $signed(RDATA_O[15:0]);
wire signed [15:0] seg1 = $signed(OMEM_Data_om[31:16])  + $signed(RDATA_O[31:16]);
wire signed [15:0] seg2 = $signed(OMEM_Data_om[47:32])  + $signed(RDATA_O[47:32]);
wire signed [15:0] seg3 = $signed(OMEM_Data_om[63:48])  + $signed(RDATA_O[63:48]);
wire [63:0] DACC = {seg3, seg2, seg1, seg0};

WBuffer u_wb(
		// INPUT
		.CLK(CLK), .RSTN(RSTN), .ODST_om(ODST_om), .ACC_ctrl(ACC_ctrl),
		.OMWrite_om(OMWrite_om), .DACC(DACC), .ROW_TOTAL(ROW_TOTAL_ctrl),
		.CLR_DP(CLR_DP_ctrl),
		// OUTPUT
		.LOAD_DONE(LOAD_DONE), .STORE_DONE(STORE_DONE), .ODST_wb(ODST_wb), 
		.EN_wb(EN_wb), .WData_wb(WData_wb), .INIT_DONE(INIT_DONE)
);


always@* begin
	if (OMSRC) begin // WBuffer 경로
		EN_O = EN_wb;
		ADDR_O = ODST_wb;
		WDATA_O = WData_wb;
		RW_O = 1'b1;
	end 
	else begin // OBuffer -> OM 경로
		EN_O = OMWrite_o;
		ADDR_O = ODST_o;
		WDATA_O = OMEM_Data_o;
		RW_O = ~ACC_ctrl;
	end
end

 

endmodule
