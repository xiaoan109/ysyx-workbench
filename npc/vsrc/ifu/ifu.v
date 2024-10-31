`include "defines.vh"
module ifu (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_pc,
  output [`INS_WIDTH-1:0] o_ins,
  output                  o_post_valid,
  input                   i_post_ready
);


  wire ren;
  wire rdata_valid;

  import "DPI-C" function void diff_read_pc(input int rtl_pc);
  always @(*) begin
    diff_read_pc(i_pc);
  end

  ifu_sram u_ifu_sram (
    .i_clk        (i_clk),
    .i_rst_n      (i_rst_n),
    .i_ren        (ren),
    .i_raddr      (i_pc),
    .o_rdata      (o_ins),
    .o_rdata_valid(rdata_valid)
  );

  assign o_post_valid = rdata_valid;
  assign ren = i_post_ready;

endmodule
