`include "defines.v"
module ImmGen(
        input [`INST_DW-1:0] instr,
        output [`XLEN-1:0] imm
    );

    wire [6:0] opcode;
    wire [`XLEN-1:0] immI;
    wire [`XLEN-1:0] immU;
    wire [`XLEN-1:0] immS;
    wire [`XLEN-1:0] immB;
    wire [`XLEN-1:0] immJ;

    assign opcode = instr[6:0];

    assign immI = {{(`XLEN-12){instr[31]}}, instr[31:20]};
    assign immU = {{(`XLEN-32){instr[31]}}, instr[31:12], 12'b0};
    assign immS = {{(`XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
    assign immB = {{(`XLEN-12){instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign immJ = {{(`XLEN-20){instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    MuxKey #(9, 7, `XLEN) u_ImmType (imm, opcode, {
                                         7'b0010111, immU,
                                         7'b0110111, immU,
                                         7'b1100011, immB,
                                         7'b1101111, immJ,
                                         7'b1100111, immI,
                                         7'b0000011, immI,
                                         7'b0100011, immS,
                                         7'b0010011, immI,
                                         7'b0011011, immI
                                     });

endmodule
