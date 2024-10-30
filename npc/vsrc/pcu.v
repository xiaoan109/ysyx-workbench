`include "defines.vh"
module pcu (
  input                   i_clk,
  input                   i_rst_n,
  input                   i_brch,
  input                   i_jal,
  input                   i_jalr,
  input                   i_zero,
  input  [`CPU_WIDTH-1:0] i_rs1,
  input  [`CPU_WIDTH-1:0] i_imm,
  input                   i_ecall,
  input                   i_mret,
  input  [`CPU_WIDTH-1:0] i_mtvec,
  input  [`CPU_WIDTH-1:0] i_mepc,
  output [`CPU_WIDTH-1:0] o_pc
);

  wire [`CPU_WIDTH-1:0] pc_next;
  wire                  except;
  wire [`CPU_WIDTH-1:0] except_pc;

  assign except = i_ecall | i_mret;
  assign except_pc = i_ecall ? i_mtvec : i_mret ? i_mepc : `CPU_WIDTH'b0;
  assign pc_next = except ? except_pc : (i_brch && ~i_zero || i_jal) ? (o_pc + i_imm) : i_jalr ? (i_rs1 + i_imm) : (o_pc + 4) ;

  stdreg #(
    .WIDTH    (`CPU_WIDTH),
    .RESET_VAL(`RESET_PC)
  ) u_stdreg (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_wen  (1'b1),
    .i_din  (pc_next),
    .o_dout (o_pc)
  );

endmodule
