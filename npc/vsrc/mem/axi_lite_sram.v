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
  // parameter SRAM_DELAY = 1;

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

`ifndef LFSR
  wire [           `SRAM_DELAY-1:0] bvalid_dly_reg;
  wire [           `SRAM_DELAY-1:0] rvalid_dly_reg;
  wire [`SRAM_DELAY*`CPU_WIDTH-1:0] rdata_dly_reg;
`else
  wire [7:0] lfsr_delay;
  wire       cnt_done;
  reg        bvalid_wait_next;
  wire       bvalid_wait_reg;
  reg        rvalid_wait_next;
  wire       rvalid_wait_reg;
`endif

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
`ifdef LFSR
    bvalid_wait_next = bvalid_wait_reg;
`endif
    if (awvalid && wvalid && (!awready && !wready) && (!bvalid || bready)) begin
      mem_wen = 1'b1;
      awready_next = 1'b1;
      wready_next = 1'b1;
`ifndef LFSR
      bvalid_next = 1'b1;
`else
      bvalid_wait_next = 1'b1;
`endif
    end
`ifdef LFSR
    if (bvalid_wait_reg && cnt_done) begin
      bvalid_next = 1'b1;
      bvalid_wait_next = 1'b0;
    end
`endif
  end

  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u_AW_W_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({awready_next, wready_next}),
    .o_dout ({awready_reg, wready_reg})
  );

`ifndef LFSR
  generate
    if (`SRAM_DELAY > 1) begin : w_long_delay
      stdreg #(
        .WIDTH(`SRAM_DELAY),
        .RESET_VAL(`SRAM_DELAY'b0)
      ) u_B_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (1'b1),
        .i_din  ({bvalid_dly_reg[`SRAM_DELAY-2:0], bvalid_next}),
        .o_dout (bvalid_dly_reg)
      );
    end else if (`SRAM_DELAY == 1) begin : w_normal_delay
      stdreg #(
        .WIDTH(`SRAM_DELAY),
        .RESET_VAL(`SRAM_DELAY'b0)
      ) u_B_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (1'b1),
        .i_din  (bvalid_next),
        .o_dout (bvalid_dly_reg)
      );
    end else begin : w_error_delay
      $error("Unsupported SRAM_DELAY! Delay must bigger than 0");
    end
  endgenerate

  assign bvalid_reg = bvalid_dly_reg[`SRAM_DELAY-1];
`else
  stdreg #(
    .WIDTH(2),
    .RESET_VAL(2'b0)
  ) u_B_dly_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({bvalid_next, bvalid_wait_next}),
    .o_dout ({bvalid_reg, bvalid_wait_reg})
  );
`endif


  import "DPI-C" function void rtl_pmem_write(
    input int       waddr,
    input int       wdata,
    input bit [3:0] wmask,
    input bit       wen
  );
  always @(*) begin
    rtl_pmem_write(awaddr, wdata, wstrb, mem_wen);
  end


  //AR/R Channel
  always @(*) begin
    mem_ren = 1'b0;
    arready_next = 1'b0;
    rvalid_next = rvalid_reg && !rready;
`ifdef LFSR
    rvalid_wait_next = rvalid_wait_reg;
`endif
    if (arvalid && !arready && (!rvalid || rready)) begin
      mem_ren = 1'b1;
      arready_next = 1'b1;
`ifndef LFSR
      rvalid_next = 1'b1;
`else
      rvalid_wait_next = 1'b1;
`endif
    end
`ifdef LFSR
    if (rvalid_wait_reg && cnt_done) begin
      rvalid_next = 1'b1;
      rvalid_wait_next = 1'b0;
    end
`endif
  end


  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_AR_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({arready_next}),
    .o_dout ({arready_reg})
  );

`ifndef LFSR
  generate
    if (`SRAM_DELAY > 1) begin : r_long_delay
      stdreg #(
        .WIDTH    (`SRAM_DELAY),
        .RESET_VAL(`SRAM_DELAY'b0)
      ) u0_R_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (1'b1),
        .i_din  ({rvalid_dly_reg[`SRAM_DELAY-2:0], rvalid_next}),
        .o_dout (rvalid_dly_reg)
      );
      stdreg #(
        .WIDTH    (`SRAM_DELAY * `CPU_WIDTH),
        .RESET_VAL({(`SRAM_DELAY * `CPU_WIDTH) {1'b0}})
      ) u1_R_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (mem_ren || (|rvalid_dly_reg[`SRAM_DELAY-2:0])), // To keep the rdata unchanged. Useful in difftest. Can be replaced with 1'b1 w/o verilator difftest.
        .i_din  ({rdata_dly_reg[(`SRAM_DELAY-1)*`CPU_WIDTH-1:0], rdata_next}),
        .o_dout (rdata_dly_reg)
      );
    end else if (`SRAM_DELAY == 1) begin : r_normal_delay
      stdreg #(
        .WIDTH    (`SRAM_DELAY),
        .RESET_VAL(`SRAM_DELAY'b0)
      ) u0_R_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (1'b1),
        .i_din  (rvalid_next),
        .o_dout (rvalid_dly_reg)
      );
      stdreg #(
        .WIDTH    (`SRAM_DELAY * `CPU_WIDTH),
        .RESET_VAL({(`SRAM_DELAY * `CPU_WIDTH) {1'b0}})
      ) u1_R_dly_reg (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n),
        .i_wen  (mem_ren),
        .i_din  (rdata_next),
        .o_dout (rdata_dly_reg)
      );
    end else begin : r_error_delay
      $error("Unsupported SRAM_DELAY! Delay must bigger than 0");
    end
  endgenerate

  assign rvalid_reg = rvalid_dly_reg[`SRAM_DELAY-1];
  assign rdata_reg  = rdata_dly_reg[(`SRAM_DELAY-1)*`CPU_WIDTH+:`CPU_WIDTH];
`else
  stdreg #(
    .WIDTH    (2),
    .RESET_VAL(2'b0)
  ) u0_R_dly_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({rvalid_next, rvalid_wait_next}),
    .o_dout ({rvalid_reg, rvalid_wait_reg})
  );

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) u1_R_dly_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (mem_ren),
    .i_din  (rdata_next),
    .o_dout (rdata_reg)
  );
`endif

  import "DPI-C" function void rtl_pmem_read(
    input  int raddr,
    output int rdata,
    input  bit ren
  );
  always @(*) begin
    rtl_pmem_read(araddr, rdata_next, mem_ren);
  end


`ifdef LFSR
  lfsr_8bit u_lfsr_8bit (
    .clk_i        (i_clk),
    .rst_ni       (i_rst_n),
    .en_i         (mem_wen || mem_ren),  // 1'b1
    .refill_way_oh(lfsr_delay)
  );

  delay_counter u_delay_counter (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_ena  (mem_wen || mem_ren),  // 1clk pulse
    .i_bound(lfsr_delay),
    .o_done (cnt_done)
  );
`endif
endmodule
