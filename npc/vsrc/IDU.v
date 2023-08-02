`include "defines.v"
module IDU(
        input [`INST_DW-1:0] instr,
        output [`REG_AW-1:0] rf_raddr1,
        output [`REG_AW-1:0] rf_raddr2,
        output [`REG_AW-1:0] rf_waddr,
        output [`XLEN-1:0] imm,
        output alu_a_sel,
        output [1:0] alu_b_sel,
        output [3:0] alu_ctrl,
        // output sext_32b,
        output rf_wen,
        output rf_wr_sel,
        output mem_wen,
        output [2:0] mem_wr_sel,
        output [2:0] branch
        // output [3:0] mul_div_rem_sel
    );

    ControlUnit u_ControlUnit(
                    .instr(instr),
                    .alu_a_sel(alu_a_sel),
                    .alu_b_sel(alu_b_sel),
                    .alu_ctrl(alu_ctrl),
                    .rf_wen(rf_wen),
                    .rf_wr_sel(rf_wr_sel),
                    .mem_wen(mem_wen),
                    .mem_wr_sel(mem_wr_sel),
                    .branch(branch)
                );

    ImmGen u_ImmGen(
               .instr(instr),
               .imm(imm)
           );

    assign rf_raddr1 = instr[19:15];
    assign rf_raddr2 = instr[24:20];
    assign rf_waddr = instr[11:7];

endmodule
