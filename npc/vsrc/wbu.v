`include "defines.vh"
module wbu (
  input  [`CPU_WIDTH-1:0] i_exu_res,
  input  [`CPU_WIDTH-1:0] i_lsu_res,
  input                   i_ld_en,
  output [`CPU_WIDTH-1:0] o_rd,
  //handshake
  input                   i_pre_valid,
  output                  o_pre_ready
);

  wire [`CPU_WIDTH-1:0] exu_res;
  wire [`CPU_WIDTH-1:0] lsu_res;

  assign exu_res = i_pre_valid ? i_exu_res : `CPU_WIDTH'b0;
  assign lsu_res = i_pre_valid ? i_lsu_res : `CPU_WIDTH'b0;

  assign o_rd = i_ld_en ? lsu_res : exu_res;

  assign o_pre_ready = 1'b1;

endmodule
