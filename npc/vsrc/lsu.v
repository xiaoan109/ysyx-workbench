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
  //AXI mem intf
  //AW Channel
  input                       awready,
  output                      awvalid,
  output [    `CPU_WIDTH-1:0] awaddr,
  output [               3:0] awid,
  output [               7:0] awlen,
  output [               2:0] awsize,
  output [               1:0] awburst,
  //W Channel
  input                       wready,
  output                      wvalid,
  output [    `CPU_WIDTH-1:0] wdata,
  output [  `CPU_WIDTH/8-1:0] wstrb,
  output                      wlast,
  //B Channel
  output                      bready,
  input                       bvalid,
  input  [               1:0] bresp,
  input  [               3:0] bid,
  //AR Channel
  input                       arready,
  output                      arvalid,
  output [    `CPU_WIDTH-1:0] araddr,
  output [               3:0] arid,
  output [               7:0] arlen,
  output [               2:0] arsize,
  output [               1:0] arburst,
  //R Channel
  output                      rready,
  input                       rvalid,
  input  [               1:0] rresp,
  input  [    `CPU_WIDTH-1:0] rdata,
  input                       rlast,
  input  [               3:0] rid
);

  localparam [7:0] BURST_LEN = 8'b1;
  // localparam [2:0] BURST_SIZE = 3'($clog2(`CPU_WIDTH / 8));
  localparam [1:0] BURST_TYPE = 2'b01;


  wire                       ren;
  wire                       wen;

  wire                       w_done_reg;
  reg                        w_done_next;
  wire                       r_done_reg;
  reg                        r_done_next;

  wire                       valid_r;  //None MEM OP

  wire [ `LSU_OPT_WIDTH-1:0] lsu_opt;

  //AXI Interface
  //AW Channel
  wire                       awvalid_reg;
  reg                        awvalid_next;
  //W Channel
  wire                       wvalid_reg;
  reg                        wvalid_next;
  wire [$clog2(BURST_LEN):0] write_index_reg;
  reg  [$clog2(BURST_LEN):0] write_index_next;
  wire                       wlast_reg;
  reg                        wlast_next;
  //B Channel
  wire                       bready_reg;
  reg                        bready_next;
  //AR Channel
  wire                       arvalid_reg;
  reg                        arvalid_next;
  //R Channel
  wire                       rready_reg;
  reg                        rready_next;


  assign awvalid = awvalid_reg;
  assign wvalid = wvalid_reg;
  assign wlast = !wlast_reg && wlast_next;
  assign bready = bready_reg;
  assign arvalid = arvalid_reg;
  assign rready = rready_reg;


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


  wire [2:0] awsize_int;
  MuxKeyWithDefault #(
    .NR_KEY  (3),
    .KEY_LEN (4),
    .DATA_LEN(3)
  ) u_awsize_mux (
    .out(awsize_int),
    .key(i_opt),
    .default_out(3'b0),
    .lut({`LSU_SB, 3'b00, `LSU_SH, 3'b01, `LSU_SW, 3'b10})
  );


  wire [`CPU_WIDTH-1:0] wdata_int;
  assign wdata_int = i_regst << ((i_addr & 2'b11) << 3);
  // Write SRAM
  stdreg #(
    .WIDTH    ((`CPU_WIDTH + 4 + 8 + 3 + 2 + `CPU_WIDTH)),
    .RESET_VAL({(`CPU_WIDTH + 4 + 8 + 3 + 2 + `CPU_WIDTH) {1'b0}})
  ) u_w_keep_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (wen),
    .i_din  ({i_addr, 4'b0, BURST_LEN - 1'b1, awsize_int, BURST_TYPE, wdata_int}),
    .o_dout ({awaddr, awid, awlen, awsize, awburst, wdata})
  );

  wire [3:0] sb_strb;
  wire [3:0] sh_strb;
  wire [3:0] sw_strb;

  assign sb_strb = (4'b0001 << awaddr[1:0]);
  assign sh_strb = (4'b0011 << awaddr[1:0]);
  assign sw_strb = (4'b1111 << awaddr[1:0]);
  MuxKeyWithDefault #(
    .NR_KEY  (3),
    .KEY_LEN (4),
    .DATA_LEN(`CPU_WIDTH / 8)
  ) u_wmask_mux (
    .out(wstrb),
    .key(lsu_opt),
    .default_out({(`CPU_WIDTH / 8) {1'b0}}),
    .lut({`LSU_SB, sb_strb, `LSU_SH, sh_strb, `LSU_SW, sw_strb})
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
    wvalid_next  = wvalid_reg && !(wready && wlast);
    if (w_done_reg && wen) begin
      awvalid_next = 1'b1;
      wvalid_next  = 1'b1;
    end
  end

  always @(*) begin
    write_index_next = write_index_reg;
    if (w_done_reg && wen) begin
      write_index_next = 0;
    end
    if (wvalid_reg && wready && (write_index_reg != BURST_LEN - 1)) begin
      write_index_next = write_index_next + 1;
    end
  end

  always @(*) begin
    wlast_next = (write_index_reg == BURST_LEN - 1) && wvalid_reg && wready;
  end


  stdreg #(
    .WIDTH    (3 + $clog2(BURST_LEN) + 1 + 1),
    .RESET_VAL({1'b1, {(2 + $clog2(BURST_LEN) + 1 + 1) {1'b0}}})
  ) u_write_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({w_done_next, awvalid_next, wvalid_next, write_index_next, wlast_next}),
    .o_dout ({w_done_reg, awvalid_reg, wvalid_reg, write_index_reg, wlast_reg})
  );


  // assign bready = 1'b1;
  always @(*) begin
    bready_next = 1'b0;
    if (bvalid && !bready_reg) begin
      bready_next = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_bready_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({bready_next}),
    .o_dout ({bready_reg})
  );

  wire [2:0] arsize_int;
  MuxKeyWithDefault #(
    .NR_KEY  (5),
    .KEY_LEN (4),
    .DATA_LEN(3)
  ) u_arsize_mux (
    .out(arsize_int),
    .key(i_opt),
    .default_out(3'b0),
    .lut({`LSU_LB, 3'b00, `LSU_LH, 3'b01, `LSU_LW, 3'b10, `LSU_LBU, 3'b00, `LSU_LHU, 3'b01})
  );

  // Read SRAM
  stdreg #(
    .WIDTH    (`CPU_WIDTH + 4 + 8 + 3 + 2),
    .RESET_VAL({(`CPU_WIDTH + 4 + 8 + 3 + 2) {1'b0}})
  ) u_r_keep_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (ren),
    .i_din  ({i_addr, 4'b0, BURST_LEN - 1'b1, arsize_int, BURST_TYPE}),
    .o_dout ({araddr, arid, arlen, arsize, arburst})
  );

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
    .WIDTH    (2),
    .RESET_VAL({2'b10})
  ) u_read_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({r_done_next, arvalid_next}),
    .o_dout ({r_done_reg, arvalid_reg})
  );

  wire [`CPU_WIDTH-1:0] rdata_int;
  assign rdata_int = rdata >> ((araddr & 2'b11) << 3);

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
      {{24{rdata_int[7]}}, rdata_int[7:0]},
      `LSU_LH,
      {{16{rdata_int[15]}}, rdata_int[15:0]},
      `LSU_LW,
      rdata_int,
      `LSU_LBU,
      {24'b0, rdata_int[7:0]},
      `LSU_LHU,
      {16'b0, rdata_int[15:0]}
    })
  );


  // assign rready = 1'b1;
  always @(*) begin
    rready_next = rready_reg && !(rvalid && rlast);
    if (rvalid && !rready_reg) begin
      rready_next = 1'b1;
    end
  end

  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) u_rready_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  ({rready_next}),
    .o_dout ({rready_reg})
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
  assign o_post_valid = (!w_done_reg && bvalid && bready_reg) || (!r_done_reg && rvalid && rready_reg) || (w_done_reg && r_done_reg && valid_r);


endmodule
