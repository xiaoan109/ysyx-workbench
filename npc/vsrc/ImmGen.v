`include "defines.v"
module ImmGen(
        input [`INST_DW-1:7] instr,
        input [2:0] ExtOp,
        output [`XLEN-1:0] imm
    );

    wire [`XLEN-1:0] immI;
    wire [`XLEN-1:0] immU;
    wire [`XLEN-1:0] immS;
    wire [`XLEN-1:0] immB;
    wire [`XLEN-1:0] immJ;

    assign immI = {{(`XLEN-12){instr[31]}}, instr[31:20]};
    assign immU = {{(`XLEN-32){instr[31]}}, instr[31:12], 12'b0};
    assign immS = {{(`XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
    assign immB = {{(`XLEN-12){instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign immJ = {{(`XLEN-20){instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    MuxKey #(.NR_KEY(5), .KEY_LEN(3), .DATA_LEN(`XLEN)) u_ImmType (
               .out(imm),
               .key(ExtOp),
               .lut({
                        3'b000, immI,
                        3'b001, immU,
                        3'b010, immS,
                        3'b011, immB,
                        3'b100, immJ
                    })
           );

endmodule
