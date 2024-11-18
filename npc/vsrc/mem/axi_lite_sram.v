`include "defines.vh"
module axi_lite_sram (
  input  wire                    i_clk,
  input  wire                    i_rst_n,
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

  reg                   mem_wen;
  reg                   mem_ren;

  wire                  awready_reg;
  reg                   awready_next;
  wire                  wready_reg;
  reg                   wready_next;
  wire                  bvalid_reg;
  reg                   bvalid_next;
  wire                  arready_reg;
  reg                   arready_next;
  wire                  rvalid_reg;
  reg                   rvalid_next;
  wire [`CPU_WIDTH-1:0] rdata_reg;
  reg  [`CPU_WIDTH-1:0] rdata_next;

  // TODO: Memory is not always ready
  assign awready = awready_reg;
  assign wready  = wready_reg;
  assign bvalid  = bvalid_reg;
  assign bresp   = 2'b00;  // Always OK
  assign arready = arready_reg;
  assign rvalid  = rvalid_reg;
  assign rresp   = 2'b00;  // Always OK
  assign rdata   = rdata_reg;


  //AW/W/B Channel
  always @(*) begin
    mem_wen = 1'b0;
    awready_next = 1'b0;
    wready_next = 1'b0;
    bvalid_next = bvalid_reg && !bready;
    if (awvalid && wvalid && (!awready && !wready) && (!bvalid || bready)) begin
      mem_wen = 1'b1;
      awready_next = 1'b1;
      wready_next = 1'b1;
      bvalid_next = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(3'b0)
  ) u_AW_W_B_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({awready_next, wready_next, bvalid_next}),
    .o_dout ({awready_reg, wready_reg, bvalid_reg})
  );

  import "DPI-C" function void rtl_pmem_read(
    input  int raddr,
    output int rdata,
    input  bit ren
  );
  always @(*) begin
    rtl_pmem_write(awaddr, wdata, wstrb, mem_wen);
  end


  //AR/R Channel
  always @(*) begin
    mem_ren = 1'b0;
    arready_next = 1'b0;
    rvalid_next = rvalid_reg && !rready;
    if (arvalid && !arready && (!rvalid || rready)) begin
      mem_ren = 1'b1;
      arready_next = 1'b1;
      rvalid_next = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH + 2),
    .RESET_VAL({(`CPU_WIDTH + 2) {1'b0}})
  ) u_AR_R_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({arready_next, rvalid_next, rdata_next}),
    .o_dout ({arready_reg, rvalid_reg, rdata_reg})
  );

  import "DPI-C" function void rtl_pmem_write(
    input int       waddr,
    input int       wdata,
    input bit [3:0] wmask,
    input bit       wen
  );
  always @(*) begin
    rtl_pmem_read(araddr, rdata_next, mem_ren);
  end


endmodule
