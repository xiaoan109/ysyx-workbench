`include "defines.vh"
module wbu (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_exu_res,
  input  [`CPU_WIDTH-1:0] i_lsu_res,
  input                   i_ld_en,
  input                   i_rdwen,
  output [`CPU_WIDTH-1:0] o_rd,
  //handshake
  input                   i_pre_valid,  //lsu
  input                   i_exu_valid,  //multi_cycle cpu needed
  output                  o_pre_ready,
  output                  o_rdwen
);

  wire [`CPU_WIDTH-1:0] exu_res;
  // wire [`CPU_WIDTH-1:0] exu_res_reg;
  wire [`CPU_WIDTH-1:0] lsu_res;
  wire                  rdwen;

  wire                  status;

  // assign exu_res = i_exu_valid ? i_exu_res : `CPU_WIDTH'b0;
  assign exu_res = i_exu_res;
  assign lsu_res = i_pre_valid ? i_lsu_res : `CPU_WIDTH'b0;

  // stdreg #(
  //   .WIDTH(`CPU_WIDTH),
  //   .RESET_VAL(`CPU_WIDTH'b0)
  // ) u_exu_reg (
  //   .i_clk  (i_clk),
  //   .i_rst_n(i_rst_n),
  //   .i_wen  (i_exu_valid),
  //   .i_din  (exu_res),
  //   .o_dout (exu_res_reg)
  // );

  stdreg #(
    .WIDTH(1),
    .RESET_VAL(1'b0)
  ) u_rdwen_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_exu_valid),
    .i_din  (i_rdwen),
    .o_dout (rdwen)
  );

  assign o_rd = i_ld_en ? lsu_res : exu_res;

  assign o_pre_ready = !i_exu_valid && !i_pre_valid;

  assign status = i_pre_valid;

  assign o_rdwen = rdwen && i_pre_valid;

  import "DPI-C" function void diff_read_status(input bit rtl_status);
  always @(*) begin
    diff_read_status(status);
  end

endmodule
