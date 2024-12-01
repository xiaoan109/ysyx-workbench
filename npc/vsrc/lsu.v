`include "defines.vh"
module lsu (
  input                       i_clk,
  input                       i_rst_n,
  input  [`LSU_OPT_WIDTH-1:0] i_opt,         // lsu i_opt.
  input  [    `CPU_WIDTH-1:0] i_addr,        // mem i_addr. from exu result.
  input  [    `CPU_WIDTH-1:0] i_regst,       // for st.
  output [    `CPU_WIDTH-1:0] o_regld,       // for ld.
  //handshake
  input                       i_pre_valid,
  output                      o_pre_ready,
  output                      o_post_valid,
  input                       i_post_ready
);

  /* verilator lint_off UNUSEDSIGNAL */
  wire                      ren;
  wire                      wen;

  wire                      w_done_reg;
  reg                       w_done_next;
  wire                      r_done_reg;
  reg                       r_done_next;

  wire                      valid_r;  //None MEM OP

  wire [`LSU_OPT_WIDTH-1:0] lsu_opt;


  //AXI Lite Interface
  //AW Channel
  wire [    `CPU_WIDTH-1:0] awaddr;
  wire                      awvalid_reg;
  reg                       awvalid_next;
  wire                      awready;
  //W Channel
  wire [    `CPU_WIDTH-1:0] wdata;
  wire [  `CPU_WIDTH/8-1:0] wstrb;
  wire                      wvalid_reg;
  reg                       wvalid_next;
  wire                      wready;
  //B Channel
  wire [               1:0] bresp;
  wire                      bvalid;
  wire                      bready;
  //AR Channel
  wire [    `CPU_WIDTH-1:0] araddr;
  wire                      arvalid_reg;
  reg                       arvalid_next;
  wire                      arready;
  //R Channel
  wire [    `CPU_WIDTH-1:0] rdata;
  wire [               1:0] rresp;
  wire                      rvalid;
  wire                      rready;

  assign ren = !i_opt[0] && (i_opt != `LSU_NOP) && i_pre_valid;
  assign wen = i_opt[0] && (i_opt != `LSU_NOP) && i_pre_valid;

  stdreg #(
    .WIDTH    (`LSU_OPT_WIDTH),
    .RESET_VAL(`LSU_OPT_WIDTH'b0)
  ) u_opt_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_pre_valid),
    .i_din  (i_opt),
    .o_dout (lsu_opt)
  );

  // Write SRAM
  stdreg #(
    .WIDTH(`CPU_WIDTH * 2),
    .RESET_VAL({(`CPU_WIDTH * 2) {1'b0}})
  ) u_w_keep_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_pre_valid),
    .i_din  ({i_addr, i_regst}),
    .o_dout ({awaddr, wdata})
  );

  MuxKeyWithDefault #(
    .NR_KEY  (3),
    .KEY_LEN (4),
    .DATA_LEN(`CPU_WIDTH / 8)
  ) u_wmask_mux (
    .out(wstrb),
    .key(lsu_opt),
    .default_out({(`CPU_WIDTH / 8) {1'b0}}),
    .lut({`LSU_SB, 4'b0001, `LSU_SH, 4'b0011, `LSU_SW, 4'b1111})
  );

  always @(*) begin
    w_done_next = w_done_reg;
    if (wen) begin
      w_done_next = 1'b0;
    end
    if (bvalid && bready) begin
      w_done_next = 1'b1;
    end
  end

  always @(*) begin
    awvalid_next = awvalid_reg && !awready;
    wvalid_next  = wvalid_reg && !wready;
    if (w_done_reg && wen) begin
      awvalid_next = 1'b1;
      wvalid_next  = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (3),
    .RESET_VAL({1'b1, 2'b0})
  ) u_write_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({w_done_next, awvalid_next, wvalid_next}),
    .o_dout ({w_done_reg, awvalid_reg, wvalid_reg})
  );


  assign bready = 1'b1;


  // Read SRAM
  stdreg #(
    .WIDTH(`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u_r_keep_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_pre_valid),
    .i_din  (i_addr),
    .o_dout (araddr)
  );

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

  MuxKeyWithDefault #(
    .NR_KEY  (5),
    .KEY_LEN (4),
    .DATA_LEN(`CPU_WIDTH)
  ) u_rdata_mux (
    .out(o_regld),
    .key(lsu_opt),
    .default_out(`CPU_WIDTH'b0),
    .lut({
      `LSU_LB,
      {{24{rdata[7]}}, rdata[7:0]},
      `LSU_LH,
      {{16{rdata[15]}}, rdata[15:0]},
      `LSU_LW,
      rdata,
      `LSU_LBU,
      {24'b0, rdata[7:0]},
      `LSU_LHU,
      {16'b0, rdata[15:0]}
    })
  );


  assign rready = 1'b1;


  axi_lite_sram u_axi_lite_sram (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    //AW Channel
    .awaddr (awaddr),
    .awvalid(awvalid_reg),
    .awready(awready),
    //W Channel
    .wdata  (wdata),
    .wstrb  (wstrb),
    .wvalid (wvalid_reg),
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

  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_valid_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (i_pre_valid),
    .o_dout (valid_r)
  );


  assign o_pre_ready = i_post_ready;
  assign o_post_valid = (!w_done_reg && bvalid && bready) || (!r_done_reg && rvalid && rready) || (w_done_reg && r_done_reg && valid_r);


endmodule
