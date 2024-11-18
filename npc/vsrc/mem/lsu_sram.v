`include "defines.vh"
module lsu_sram (
  /* verilator lint_off UNUSEDSIGNAL */
  input                         i_clk,
  input                         i_rst_n,
  input                         i_pre_valid,
  input                         i_ren,
  input      [  `CPU_WIDTH-1:0] i_raddr,
  output reg [  `CPU_WIDTH-1:0] o_rdata,
  input                         i_wen,
  input      [  `CPU_WIDTH-1:0] i_waddr,
  input      [`CPU_WIDTH/8-1:0] i_wmask,
  input      [  `CPU_WIDTH-1:0] i_wdata,
  output                        o_mem_valid
);

  reg [`CPU_WIDTH-1:0] rdata_pre;

  import "DPI-C" function void rtl_pmem_read(
    input  int raddr,
    output int rdata,
    input  bit ren
  );

  import "DPI-C" function void rtl_pmem_write(
    input int       waddr,
    input int       wdata,
    input bit [3:0] wmask,
    input bit       wen
  );

  /* verilator lint_off SYNCASYNCNET */
  always @(i_raddr, i_ren, i_rst_n, i_waddr, i_wdata, i_wmask, i_wen) begin // TODO: Why does always @(*) call write func repeatedly ?
    rtl_pmem_read(i_raddr, rdata_pre, i_ren);
    rtl_pmem_write(i_waddr, i_wdata, i_wmask, i_wen);
  end

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) rdata_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_ren),
    .i_din  (rdata_pre),
    .o_dout (o_rdata)
  );

  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b0)
  ) rdata_valid_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (i_pre_valid),
    .o_dout (o_mem_valid)
  );

endmodule
