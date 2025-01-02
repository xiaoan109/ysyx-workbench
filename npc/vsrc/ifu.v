`include "defines.vh"
module ifu (
  input                     i_clk,
  input                     i_rst_n,
  input  [  `CPU_WIDTH-1:0] i_pc,
  output [  `INS_WIDTH-1:0] o_instr,
  output                    o_post_valid,
  input                     i_post_ready,
  //AXI mem intf
  //AW Channel
  input                     awready,
  output                    awvalid,
  output [  `CPU_WIDTH-1:0] awaddr,
  output [             3:0] awid,
  output [             7:0] awlen,
  output [             2:0] awsize,
  output [             1:0] awburst,
  //W Channel
  input                     wready,
  output                    wvalid,
  output [  `CPU_WIDTH-1:0] wdata,
  output [`CPU_WIDTH/8-1:0] wstrb,
  output                    wlast,
  //B Channel
  output                    bready,
  input                     bvalid,
  input  [             1:0] bresp,
  input  [             3:0] bid,
  //AR Channel
  input                     arready,
  output                    arvalid,
  output [  `CPU_WIDTH-1:0] araddr,
  output [             3:0] arid,
  output [             7:0] arlen,
  output [             2:0] arsize,
  output [             1:0] arburst,
  //R Channel
  output                    rready,
  input                     rvalid,
  input  [             1:0] rresp,
  input  [  `CPU_WIDTH-1:0] rdata,
  input                     rlast,
  input  [             3:0] rid
);

  localparam [7:0] BURST_LEN = 8'b1;
  localparam [2:0] BURST_SIZE = $clog2(`CPU_WIDTH / 8);
  localparam [1:0] BURST_TYPE = 2'b01;  //INCR

  wire                  ren;

  wire                  r_done_reg;
  reg                   r_done_next;

  //AXI Lite Interface
  //AR Channel
  wire                  arvalid_reg;
  reg                   arvalid_next;
  //R Channel
  wire                  rready_reg;
  reg                   rready_next;
  wire [`CPU_WIDTH-1:0] rdata_rev;

  assign arvalid = arvalid_reg;
  assign rready = rready_reg;

  assign ren = i_post_ready;



  // Write SRAM
  assign awvalid = 1'b0;
  assign awaddr = `CPU_WIDTH'b0;
  assign awid = 4'b0;
  assign awlen = 8'b0;
  assign awsize = 3'b0;
  assign awburst = 2'b0;
  assign wvalid = 1'b0;
  assign wdata = `CPU_WIDTH'b0;
  assign wstrb = {(`CPU_WIDTH / 8) {1'b0}};
  assign wlast = 1'b0;
  assign bready = 1'b0;

  // Read SRAM

  always @(*) begin
    r_done_next = r_done_reg;
    if (ren) begin
      r_done_next = 1'b0;
    end
    if (rvalid && rready_reg && rlast) begin
      r_done_next = 1'b1;
    end
  end

  always @(*) begin
    arvalid_next = arvalid_reg && !arready;
    if (r_done_reg && ren) begin
      arvalid_next = 1'b1;
    end
  end


  stdreg #(
    .WIDTH    (3),
    .RESET_VAL(3'b100)
  ) u_read_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({r_done_next, arvalid_next, rready_next}),
    .o_dout ({r_done_reg, arvalid_reg, rready_reg})
  );

  stdreg #(
    .WIDTH    (`CPU_WIDTH + 4 + 8 + 3 + 2),
    .RESET_VAL({(`CPU_WIDTH + 4 + 8 + 3 + 2) {1'b0}})
  ) u_r_keep_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (ren),
    .i_din  ({i_pc, 4'b0, BURST_LEN - 1'b1, BURST_SIZE, BURST_TYPE}),
    .o_dout ({araddr, arid, arlen, arsize, arburst})
  );

  // assign rready = 1'b1;

  always @(*) begin
    rready_next = rready_reg && !(rvalid && rlast);
    if (rvalid && !rready_reg) begin
      rready_next = 1'b1;
    end
  end


  // genvar k;
  // generate
  //   for (k = 0; k < `CPU_WIDTH / 8; k = k + 1) begin : byte_revert
  //     assign rdata_rev[k*8+:8] = rdata[(`CPU_WIDTH/8-k-1)*8+:8];
  //   end
  // endgenerate

  assign rdata_rev = rdata;
  // assign o_instr   = rdata_rev;
  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_instr_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (rvalid),
    .i_din  (rdata_rev),
    .o_dout (o_instr)
  );
  assign o_post_valid = rvalid && rready_reg && rlast;


`ifndef SYNTHESIS
  import "DPI-C" function void diff_read_pc(input int rtl_pc);
  always @(*) begin
    diff_read_pc(i_pc);
  end
`endif

endmodule
