`include "defines.v"
module EXU(
        input [`XLEN-1:0] ALUA,
        input [`XLEN-1:0] ALUB,
        input [3:0] ALUctr,
        input [2:0] Branch,
        output [`XLEN-1:0] ALUOut,
        output PCAsrc,
        output PCBsrc
    );

    wire less;
    wire zero;

    ALU u_ALU(
            .ALUA(ALUA),
            .ALUB(ALUB),
            .ALUctr(ALUctr),
            .ALUOut(ALUOut),
            .less(less),
            .zero(zero)
        );

    Branch u_Branch(
               .Branch(Branch),
               .zero(zero),
               .less(less),
               .PCAsrc(PCAsrc),
               .PCBsrc(PCBsrc)
           );

endmodule
