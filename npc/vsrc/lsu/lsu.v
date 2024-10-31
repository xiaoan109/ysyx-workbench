`include "defines.vh"
module lsu (
  /* verilator lint_off UNUSEDSIGNAL */
  input                           i_clk,
  input                           i_rst_n,
  input      [`LSU_OPT_WIDTH-1:0] i_opt,         // lsu i_opt.
  input      [    `CPU_WIDTH-1:0] i_addr,        // mem i_addr. from exu result.
  input      [    `CPU_WIDTH-1:0] i_regst,       // for st.
  output reg [    `CPU_WIDTH-1:0] o_regld,       // for ld.
  //handshake
  input                           i_pre_valid,
  output                          o_pre_ready,
  output                          o_post_valid,
  input                           i_post_ready
);

  wire ren = ~i_opt[0] && i_opt != `LSU_NOP;
  wire wen = i_opt[0] && i_opt != `LSU_NOP;
  wire [`CPU_WIDTH-1:0] raddr = i_addr;
  wire [`CPU_WIDTH-1:0] rdata;
  always @(*) begin
    case (i_opt)
      `LSU_LB:  o_regld = {{24{rdata[7]}}, rdata[7:0]};
      `LSU_LH:  o_regld = {{16{rdata[15]}}, rdata[15:0]};
      `LSU_LW:  o_regld = rdata;
      `LSU_LBU: o_regld = {24'b0, rdata[7:0]};
      `LSU_LHU: o_regld = {16'b0, rdata[15:0]};
      default:  o_regld = `CPU_WIDTH'b0;
    endcase
  end

  reg  [`CPU_WIDTH/8-1:0] mask;
  wire [`CPU_WIDTH/8-1:0] wmask;
  wire [`CPU_WIDTH-1:0] waddr, wdata;
  always @(*) begin
    case (i_opt)
      `LSU_SB: mask = 'b0001;
      `LSU_SH: mask = 'b0011;
      `LSU_SW: mask = 'b1111;
      default: mask = 'b0;
    endcase
  end

  // Due to comb logic delay, there must use an reg!!
  // Think about this situation: if waddr and wdata is not ready, but write it to mem immediately. it's wrong! 
  // stdreg #(
  //   .WIDTH    (2 * `CPU_WIDTH + `CPU_WIDTH / 8),
  //   .RESET_VAL(0)
  // ) u_stdreg (
  //   .i_clk  (i_clk),
  //   .i_rst_n(i_rst_n),
  //   .i_wen  (wen),
  //   .i_din  ({i_addr, i_regst, mask}),
  //   .o_dout ({waddr, wdata, wmask})
  // );

  assign waddr = i_addr;
  assign wdata = i_regst;
  assign wmask = mask;

  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  // import "DPI-C" function void rtl_pmem_read(
  //   input  int raddr,
  //   output int rdata,
  //   input  bit ren
  // );
  // import "DPI-C" function void rtl_pmem_write(
  //   input int                    waddr,
  //   input int                    wdata,
  //   input bit [`CPU_WIDTH/8-1:0] wmask,
  //   input bit                    wen
  // );
  // always @(*) begin
  //   rtl_pmem_read(raddr, rdata, ren);
  //   rtl_pmem_write(waddr, wdata, wmask, wen);
  // end

  wire mem_valid;
  lsu_sram u_lsu_sram (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),
    .i_pre_valid(i_pre_valid),
    .i_ren      (ren),
    .i_raddr    (raddr),
    .o_rdata    (rdata),
    .i_wen      (wen),
    .i_waddr    (waddr),
    .i_wmask    (wmask),
    .i_wdata    (wdata),
    .o_mem_valid(mem_valid)
  );


  assign o_pre_ready  = i_post_ready;
  assign o_post_valid = mem_valid;


endmodule
