`include "defines.vh"
module ifu (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_pc,
  output [`INS_WIDTH-1:0] o_instr,
  output                  o_post_valid,
  input                   i_post_ready,
  //AXI lite mem intf
  /* verilator lint_off UNUSEDSIGNAL */
  //AW Channel
  output [`CPU_WIDTH-1:0] awaddr,
  output                  awvalid,

  input                     awready,
  //W Channel
  output [  `CPU_WIDTH-1:0] wdata,
  output [`CPU_WIDTH/8-1:0] wstrb,
  output                    wvalid,
  input                     wready,
  //B Channel
  input  [             1:0] bresp,
  input                     bvalid,
  output                    bready,
  //AR Channel
  output [  `CPU_WIDTH-1:0] araddr,
  output                    arvalid,
  input                     arready,
  //R Channel
  input  [  `CPU_WIDTH-1:0] rdata,
  input  [             1:0] rresp,
  input                     rvalid,
  output                    rready
  /* verilator lint_on UNUSEDSIGNAL */
);


  wire ren;

  wire r_done_reg;
  reg  r_done_next;

  //AXI Lite Interface
  //AR Channel
  wire arvalid_reg;
  reg  arvalid_next;
  //R Channel
  wire rready_reg;
  reg  rready_next;

  assign arvalid = arvalid_reg;
  assign rready  = rready_reg;

  wire [7:0] lfsr_delay;  // assert > 0
  wire       cnt_done;
  wire       arvalid_wait_reg;
  reg        arvalid_wait_next;
  wire       rready_wait_reg;
  reg        rready_wait_next;

  wire       rvalid_reg;  //edge detect
  wire       rvalid_pulse;

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
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_rvalid_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (rvalid),
    .o_dout (rvalid_reg)
  );

  assign rvalid_pulse = rvalid && !rvalid_reg;


`ifdef LFSR
  lfsr_8bit #(
    .SEED (8'b1),
    .WIDTH(8)
  ) u_lfsr_8bit (
    .clk_i        (i_clk),
    .rst_ni       (i_rst_n),
    .en_i         (ren || rvalid_pulse),  // 1'b1
    .refill_way_oh(lfsr_delay)
  );
`else
  assign lfsr_delay = `SRAM_DELAY;
`endif

  delay_counter u_delay_counter (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_ena  (ren || rvalid_pulse),  // 1clk pulse
    .i_bound(lfsr_delay - 1'b1),    //minus 1 is the real delay
    .o_done (cnt_done)
  );

  assign o_instr      = rdata;
  assign o_post_valid = rvalid && rready_reg;

endmodule
