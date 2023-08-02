`include "defines.v"
module EXU(
        input [`XLEN-1:0] alu_a,
        input [`XLEN-1:0] alu_b,
        input [3:0] alu_ctrl,
        input [2:0] branch,
        // input sext_32b,
        // input [3:0] mul_div_rem_sel,
        output [`XLEN-1:0] alu_out,
        output pc_a_sel,
        output pc_b_sel
    );

    wire less;
    wire zero;

    ALU u_ALU(
            .alu_a(alu_a),
            .alu_b(alu_b),
            .alu_ctrl(alu_ctrl),
            .alu_out(alu_out),
            .less(less),
            .zero(zero)
        );

    Branch u_Branch(
               .branch(branch),
               .zero(zero),
               .less(less),
               .pc_a_sel(pc_a_sel),
               .pc_b_sel(pc_b_sel)
           );

endmodule
