`include "defines.vh"
module alu (
  input      [    `CPU_WIDTH-1:0] i_src1,
  input      [    `CPU_WIDTH-1:0] i_src2,
  input      [`EXU_OPT_WIDTH-1:0] i_opt,
  output reg [    `CPU_WIDTH-1:0] o_alu_res,
  output reg                      o_sububit
);
  /* verilator lint_off UNUSEDSIGNAL */
  wire [63:0] tmp_res;
  /* verilator lint_on UNUSEDSIGNAL */
  
  always @(*) begin
    o_alu_res = `CPU_WIDTH'b0;
    o_sububit = 1'b0;
    case (i_opt)
      `ALU_ADD: o_alu_res = i_src1 + i_src2;
      `ALU_SUB: o_alu_res = i_src1 - i_src2;
      `ALU_AND: o_alu_res = i_src1 & i_src2;
      `ALU_OR: o_alu_res = i_src1 | i_src2;
      `ALU_XOR: o_alu_res = i_src1 ^ i_src2;
      `ALU_SLL: o_alu_res = i_src1 << i_src2[4:0];
      `ALU_SRL: o_alu_res = i_src1 >> i_src2[4:0];
      `ALU_SRA: o_alu_res = tmp_res[31:0];
      `ALU_SUBU:
      {o_sububit, o_alu_res} = {1'b0, i_src1} - {1'b0, i_src2};  // use for sltu,bltu,bgeu
      default: ;
    endcase
  end

  assign tmp_res = {{{32{i_src1[31]}}, i_src1} >> i_src2[5:0]};
endmodule
