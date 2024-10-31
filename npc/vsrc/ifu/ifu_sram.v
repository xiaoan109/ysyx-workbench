`include "defines.vh"
module ifu_sram (
  input                       i_clk,
  input                       i_rst_n,
  input                       i_ren,
  input      [`CPU_WIDTH-1:0] i_raddr,
  output reg [`CPU_WIDTH-1:0] o_rdata,
  output reg                  o_rdata_valid
);

  reg [`CPU_WIDTH-1:0] rdata_pre;

  import "DPI-C" function void rtl_pmem_read(
    input  int raddr,
    output int rdata,
    input  bit ren
  );
  always @(*) begin
    rtl_pmem_read(i_raddr, rdata_pre, i_ren && i_rst_n);
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
    .i_din  (i_ren),
    .o_dout (o_rdata_valid)
  );

endmodule
