`include "defines.vh"
module axi_lite_clint (
  input                          i_clk,
  input                          i_rst_n,
  //AW Channel
  input  wire [  `CPU_WIDTH-1:0] awaddr,
  input  wire                    awvalid,
  output wire                    awready,
  //W Channel
  input  wire [  `CPU_WIDTH-1:0] wdata,
  input  wire [`CPU_WIDTH/8-1:0] wstrb,
  input  wire                    wvalid,
  output wire                    wready,
  //B Channel
  output wire [             1:0] bresp,
  output wire                    bvalid,
  input  wire                    bready,
  //AR Channel
  input  wire [  `CPU_WIDTH-1:0] araddr,
  input  wire                    arvalid,
  output wire                    arready,
  //R Channel
  output wire [  `CPU_WIDTH-1:0] rdata,
  output wire [             1:0] rresp,
  output wire                    rvalid,
  input  wire                    rready
);

  reg                     reg_ren;

  wire                    arready_reg;
  reg                     arready_next;
  wire                    rvalid_reg;
  reg                     rvalid_next;
  wire [  `CPU_WIDTH-1:0] rdata_reg;
  reg  [  `CPU_WIDTH-1:0] rdata_next;


  wire [`CPU_WIDTH*2-1:0] mtime_reg;  //addr: 0x0
  reg  [`CPU_WIDTH*2-1:0] mtime_next;

  assign awready = 1'b0;
  assign wready  = 1'b0;
  assign bvalid  = 1'b0;
  assign bresp   = 2'b00;  // Always OK
  assign arready = arready_reg;
  assign rvalid  = rvalid_reg;
  assign rresp   = 2'b00;  // Always OK
  assign rdata   = rdata_reg;

  import "DPI-C" function void difftest_skip();

  //AR/R Channel
  always @(*) begin
    reg_ren = 1'b0;
    arready_next = 1'b0;
    rvalid_next = rvalid_reg && !rready;
    if (arvalid && !arready && (!rvalid || rready)) begin
`ifndef SYNTHESIS
      difftest_skip();
`endif
      reg_ren = 1'b1;
      arready_next = 1'b1;
      rvalid_next = 1'b1;
    end
  end


  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_AR_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({arready_next, rvalid_next}),
    .o_dout ({arready_reg, rvalid_reg})
  );



  always @(*) begin
    case (araddr[11:2])  //0xa000_2000 ~ 0xa000_2fff
      10'h0:   rdata_next = mtime_reg[`CPU_WIDTH-1:0];
      10'h1:   rdata_next = mtime_reg[`CPU_WIDTH*2-1:`CPU_WIDTH];
      default: rdata_next = `CPU_WIDTH'b0;
    endcase
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (reg_ren),
    .i_din  (rdata_next),
    .o_dout (rdata_reg)
  );


  //timer

  always @(*) begin
    mtime_next = mtime_reg + 1'b1;
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH * 2),
    .RESET_VAL({(`CPU_WIDTH * 2) {1'b0}})
  ) u_mtime_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (mtime_next),
    .o_dout (mtime_reg)
  );


endmodule
