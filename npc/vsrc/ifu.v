`include "defines.vh"
module ifu (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_pc,
  output [`INS_WIDTH-1:0] o_instr,
  output                  o_post_valid,
  input                   i_post_ready
);


  wire                    ren;

  wire                    r_done_reg;
  reg                     r_done_next;

  /* verilator lint_off UNUSEDSIGNAL */
  //AXI Lite Interface
  //AW Channel
  wire [  `CPU_WIDTH-1:0] awaddr;
  wire                    awvalid;
  wire                    awready;
  //W Channel
  wire [  `CPU_WIDTH-1:0] wdata;
  wire [`CPU_WIDTH/8-1:0] wstrb;
  wire                    wvalid;
  wire                    wready;
  //B Channel
  wire [             1:0] bresp;
  wire                    bvalid;
  wire                    bready;
  //AR Channel
  wire [  `CPU_WIDTH-1:0] araddr;
  wire                    arvalid_reg;
  reg                     arvalid_next;
  wire                    arready;
  //R Channel
  wire [  `CPU_WIDTH-1:0] rdata;
  wire [             1:0] rresp;
  wire                    rvalid;
  wire                    rready;

  assign ren = i_post_ready;

  import "DPI-C" function void diff_read_pc(input int rtl_pc);
  always @(*) begin
    diff_read_pc(i_pc);
  end


  // Write SRAM
  assign awaddr  = `CPU_WIDTH'b0;
  assign awvalid = 1'b0;
  assign wdata   = `CPU_WIDTH'b0;
  assign wstrb   = {(`CPU_WIDTH / 8) {1'b0}};
  assign wvalid  = 1'b0;
  assign bready  = 1'b0;

  // Read SRAM
  assign araddr  = i_pc;

  always @(*) begin
    r_done_next = r_done_reg;
    if (ren) begin
      r_done_next = 1'b0;
    end
    if (rvalid && rready) begin
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
    .WIDTH    (2),
    .RESET_VAL({1'b1, 1'b0})
  ) u_read_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({r_done_next, arvalid_next}),
    .o_dout ({r_done_reg, arvalid_reg})
  );

  assign rready = 1'b1;



  axi_lite_sram u_axi_lite_sram (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    //AW Channel
    .awaddr (awaddr),
    .awvalid(awvalid),
    .awready(awready),
    //W Channel
    .wdata  (wdata),
    .wstrb  (wstrb),
    .wvalid (wvalid),
    .wready (wready),
    //B Channel
    .bresp  (bresp),
    .bvalid (bvalid),
    .bready (bready),
    //AR Channel
    .araddr (araddr),
    .arvalid(arvalid_reg),
    .arready(arready),
    //R Channel
    .rdata  (rdata),
    .rresp  (rresp),
    .rvalid (rvalid),
    .rready (rready)
  );

  assign o_instr      = rdata;
  assign o_post_valid = rvalid && rready;

endmodule
