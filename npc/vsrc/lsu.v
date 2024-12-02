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
  input                       i_post_ready,
  //AXI lite mem intf
  /* verilator lint_off UNUSEDSIGNAL */
  //AW Channel
  output [    `CPU_WIDTH-1:0] awaddr,
  output                      awvalid,
  input                       awready,
  //W Channel
  output [    `CPU_WIDTH-1:0] wdata,
  output [  `CPU_WIDTH/8-1:0] wstrb,
  output                      wvalid,
  input                       wready,
  //B Channel
  input  [               1:0] bresp,
  input                       bvalid,
  output                      bready,
  //AR Channel
  output [    `CPU_WIDTH-1:0] araddr,
  output                      arvalid,
  input                       arready,
  //R Channel
  input  [    `CPU_WIDTH-1:0] rdata,
  input  [               1:0] rresp,
  input                       rvalid,
  output                      rready
  /* verilator lint_on UNUSEDSIGNAL */
);

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
  wire                      awvalid_reg;
  reg                       awvalid_next;
  //W Channel
  wire                      wvalid_reg;
  reg                       wvalid_next;
  //B Channel
  wire                      bready_reg;
  reg                       bready_next;
  //AR Channel
  wire                      arvalid_reg;
  reg                       arvalid_next;
  //R Channel
  wire                      rready_reg;
  reg                       rready_next;


  assign awvalid = awvalid_reg;
  assign wvalid  = wvalid_reg;
  assign bready  = bready_reg;
  assign arvalid = arvalid_reg;
  assign rready  = rready_reg;

  wire [7:0] lfsr_delay;
  wire       cnt_done;
  wire       awvalid_wait_reg;
  reg        awvalid_wait_next;
  wire       wvalid_wait_reg;
  reg        wvalid_wait_next;
  wire       arvalid_wait_reg;
  reg        arvalid_wait_next;

  wire       bready_wait_reg;
  reg        bready_wait_next;
  wire       rready_wait_reg;
  reg        rready_wait_next;


  wire       rvalid_reg;  //edge detect
  wire       rvalid_pulse;
  wire       bvalid_reg;  //edge detect
  wire       bvalid_pulse;

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
    if (bvalid && bready_reg) begin
      w_done_next = 1'b1;
    end
  end

  always @(*) begin
    awvalid_next = awvalid_reg && !awready;
    wvalid_next = wvalid_reg && !wready;
    awvalid_wait_next = awvalid_wait_reg;
    wvalid_wait_next = wvalid_wait_reg;
    if (w_done_reg && wen) begin
      if (lfsr_delay == 8'b1) begin
        awvalid_next = 1'b1;
        wvalid_next  = 1'b1;
      end else begin
        awvalid_wait_next = 1'b1;
        wvalid_wait_next  = 1'b1;
      end
    end
    if (awvalid_wait_reg && wvalid_wait_reg && cnt_done) begin
      awvalid_next = 1'b1;
      wvalid_next = 1'b1;
      awvalid_wait_next = 1'b0;
      wvalid_wait_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH    (5),
    .RESET_VAL(5'b10000)
  ) u_write_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({w_done_next, awvalid_next, wvalid_next, awvalid_wait_next, wvalid_wait_next}),
    .o_dout ({w_done_reg, awvalid_reg, wvalid_reg, awvalid_wait_reg, wvalid_wait_reg})
  );


  // assign bready = 1'b1;
  always @(*) begin
    bready_next = 1'b0;
    bready_wait_next = bready_wait_reg;
    if (bvalid && !bready_reg) begin
      if (lfsr_delay == 8'b1) begin
        bready_next = 1'b1;
      end else begin
        bready_wait_next = 1'b1;
      end
    end
    if (bready_wait_reg && cnt_done) begin
      bready_next = 1'b1;
      bready_wait_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_bready_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({bready_next, bready_wait_next}),
    .o_dout ({bready_reg, bready_wait_reg})
  );

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
    if (rvalid && rready_reg) begin
      r_done_next = 1'b1;
    end
  end

  always @(*) begin
    arvalid_next = arvalid_reg && !arready;
    arvalid_wait_next = arvalid_wait_reg;
    if (r_done_reg && ren) begin
      if (lfsr_delay == 8'b1) begin
        arvalid_next = 1'b1;
      end else begin
        arvalid_wait_next = 1'b1;
      end
    end
    if (arvalid_wait_reg && cnt_done) begin
      arvalid_next = 1'b1;
      arvalid_wait_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH    (3),
    .RESET_VAL({3'b100})
  ) u_read_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({r_done_next, arvalid_next, arvalid_wait_next}),
    .o_dout ({r_done_reg, arvalid_reg, arvalid_wait_reg})
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


  // assign rready = 1'b1;
  always @(*) begin
    rready_next = 1'b0;
    rready_wait_next = rready_wait_reg;
    if (rvalid && !rready_reg) begin
      if (lfsr_delay == 8'b1) begin
        rready_next = 1'b1;
      end else begin
        rready_wait_next = 1'b1;
      end
    end
    if (rready_wait_reg && cnt_done) begin
      rready_next = 1'b1;
      rready_wait_next = 1'b0;
    end
  end

  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_rready_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({rready_next, rready_wait_next}),
    .o_dout ({rready_reg, rready_wait_reg})
  );


  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_B_R_valid_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({bvalid, rvalid}),
    .o_dout ({bvalid_reg, rvalid_reg})
  );

  assign rvalid_pulse = rvalid && !rvalid_reg;
  assign bvalid_pulse = bvalid && !bvalid_reg;

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

`ifdef LFSR
  lfsr_8bit #(
    .SEED (8'd2),
    .WIDTH(8)
  ) u_lfsr_8bit (
    .clk_i        (i_clk),
    .rst_ni       (i_rst_n),
    .en_i         (wen || ren || rvalid_pulse || bvalid_pulse),  // 1'b1
    .refill_way_oh(lfsr_delay)
  );
`else
  assign lfsr_delay = `SRAM_DELAY;
`endif

  delay_counter u_delay_counter (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_ena(wen || ren || rvalid_pulse || bvalid_pulse),  // 1clk pulse
    .i_bound(lfsr_delay - 1'b1),  //minus 1 is the real delay
    .o_done(cnt_done)
  );


  assign o_pre_ready = i_post_ready;
  assign o_post_valid = (!w_done_reg && bvalid && bready_reg) || (!r_done_reg && rvalid && rready_reg) || (w_done_reg && r_done_reg && valid_r);


endmodule
