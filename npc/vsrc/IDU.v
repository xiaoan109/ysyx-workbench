`include "defines.v"
module IDU(
        input [`INST_DW-1:0] instr,
        output [`REG_AW-1:0] rs1,
        output [`REG_AW-1:0] rs2,
        output [`REG_AW-1:0] rd,
        output [`XLEN-1:0] imm,
        output ALUAsrc,
        output [1:0] ALUBsrc,
        output [3:0] ALUctr,
        output RegWr,
        output MemtoReg,
        output MemWrite,
        output MemRead,
        output [2:0] MemOP,
        output [2:0] Branch
    );

    wire [2:0] ExtOp;

    ControlUnit u_ControlUnit(
                    .op(instr[6:0]),
                    .func3(instr[14:12]),
                    .func7(instr[31:25]),
                    .ExtOp(ExtOp),
                    .ALUAsrc(ALUAsrc),
                    .ALUBsrc(ALUBsrc),
                    .ALUctr(ALUctr),
                    .RegWr(RegWr),
                    .MemtoReg(MemtoReg),
                    .MemWrite(MemWrite),
                    .MemRead(MemRead),
                    .MemOP(MemOP),
                    .Branch(Branch)
                );

    ImmGen u_ImmGen(
               .instr(instr),
               .ExtOp(ExtOp),
               .imm(imm)
           );

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];

endmodule
