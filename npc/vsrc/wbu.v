`include "defines.vh"
module wbu (
  input                   i_clk,
  input                   i_rst_n,
  input  [`CPU_WIDTH-1:0] i_exu_res,    //exu
  input  [`CPU_WIDTH-1:0] i_lsu_res,    //lsu
  input                   i_ld_en,      //idu
  input                   i_rdwen,      //idu
  input  [`REG_ADDRW-1:0] i_rdid,       //idu
  input                   i_csrdwen,    //idu
  input  [`CSR_ADDRW-1:0] i_csrdid,     //idu
  input  [`CPU_WIDTH-1:0] i_csrd,       //exu
  output                  o_rdwen,
  output [`REG_ADDRW-1:0] o_rdid,
  output [`CPU_WIDTH-1:0] o_rd,
  output                  o_csrdwen,
  output [`CSR_ADDRW-1:0] o_csrdid,
  output [`CPU_WIDTH-1:0] o_csrd,
  //handshake
  input                   i_idu_valid,  //idu
  input                   i_lsu_valid,  //lsu
  input                   i_exu_valid,  //multi_cycle cpu needed
  output                  o_wbu_ready

);

  wire [`CPU_WIDTH-1:0] exu_res;
  wire [`CPU_WIDTH-1:0] lsu_res;
  wire                  ld_en;
  wire                  rdwen;
  wire                  csrdwen;
  wire                  status;

  assign lsu_res = i_lsu_res;

  stdreg #(
    .WIDTH    (3 + `REG_ADDRW + `CSR_ADDRW),
    .RESET_VAL({(3 + `REG_ADDRW + `CSR_ADDRW) {1'b0}})
  ) u_idu_sig_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_idu_valid),
    .i_din  ({i_ld_en, i_rdwen, i_rdid, i_csrdwen, i_csrdid}),
    .o_dout ({ld_en, rdwen, o_rdid, csrdwen, o_csrdid})
  );

  stdreg #(
    .WIDTH    (`CPU_WIDTH * 2),
    .RESET_VAL({(`CPU_WIDTH * 2) {1'b0}})
  ) u_exu_sig_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (i_exu_valid),
    .i_din  ({i_exu_res, i_csrd}),
    .o_dout ({exu_res, o_csrd})
  );

  // TODO: temp
  stdreg #(
    .WIDTH    (1),
    .RESET_VAL(1'b1)
  ) u_ready_reg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (i_lsu_valid),
    .o_dout (o_wbu_ready)
  );

  assign o_rd = ld_en ? lsu_res : exu_res;

  assign status = i_lsu_valid;

  assign o_rdwen = rdwen && i_lsu_valid;

  assign o_csrdwen = csrdwen && i_lsu_valid;

  import "DPI-C" function void diff_read_status(input bit rtl_status);
  always @(*) begin
    diff_read_status(status);
  end

endmodule
