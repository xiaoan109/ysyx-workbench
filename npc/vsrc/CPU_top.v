`include "defines.v"
module CPU_top(
        input clk,
        input rst
    );

    wire [`PC_DW-1:0] next_pc;
    wire [`PC_DW-1:0] pc;
    wire [`INST_DW-1:0] instr;
    // RegFile
    wire [`REG_AW-1:0] rs1;
    wire [`REG_AW-1:0] rs2;
    wire [`REG_AW-1:0] rd;
    wire RegWr;
    wire MemtoReg;
    wire [`REG_DW-1:0] rd_data;
    wire [`REG_DW-1:0] rs1_data;
    wire [`REG_DW-1:0] rs2_data;
    // Immediate Number
    wire [`XLEN-1:0] imm;
    // Memory Access
    wire MemWrite;
    wire MemRead;
    wire [2:0] MemOP;
    wire [`XLEN-1:0] MemAddr;
    wire [`XLEN-1:0] MemWdata;
    wire [`XLEN-1:0] MemRdata; // dmem rdata after byte sel

    // Branch
    wire [2:0] Branch;
    // ALU
    wire ALUAsrc;
    wire [1:0] ALUBsrc;
    wire [`XLEN-1:0] ALUA;
    wire [`XLEN-1:0] ALUB;
    wire [3:0] ALUctr;
    wire [`XLEN-1:0] ALUOut;
    // PC
    wire PCAsrc;
    wire PCBsrc;
    wire [`XLEN-1:0] PCA;
    wire [`XLEN-1:0] PCB;
    assign next_pc = PCA + PCB;

    IFU u_IFU(
            .clk(clk),
            .rst(rst),
            .next_pc(next_pc),
            .pc(pc),
            .instr(instr)
        );

    IDU u_IDU(
            .instr(instr),
            .rs1(rs1),
            .rs2(rs2),
            .rd(rd),
            .imm(imm),
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

    EXU u_EXU(
            .ALUA(ALUA),
            .ALUB(ALUB),
            .ALUctr(ALUctr),
            .Branch(Branch),
            .ALUOut(ALUOut),
            .PCAsrc(PCAsrc),
            .PCBsrc(PCBsrc)
        );

    LSU u_LSU(
            .clk(clk),
            .rst(rst),
            .MemWrite(MemWrite),
            .MemRead(MemRead),
            .MemOP(MemOP),
            .MemAddr(MemAddr),
            .MemWdata(MemWdata),
            .MemRdata(MemRdata)
        );

    RegisterFile #(.ADDR_WIDTH(`REG_AW), .DATA_WIDTH(`REG_DW)) u_RegFile(
                     .clk(clk),
                     .wdata(rd_data),
                     .waddr(rd),
                     .wen(RegWr),
                     .raddr1(rs1),
                     .raddr2(rs2),
                     .rdata1(rs1_data),
                     .rdata2(rs2_data)
                 );

    assign ALUA = ALUAsrc ? pc : rs1_data;
    MuxKey #(.NR_KEY(3), .KEY_LEN(2), .DATA_LEN(`XLEN)) u_ALUBsrc (
               .out(ALUB),
               .key(ALUBsrc),
               .lut({
                        2'b00, rs2_data,
                        2'b01, {{(`XLEN-3){1'b0}}, 3'h4},
                        2'b10, imm
                    })
           );
    //TODO: Pass Regfile
    
    assign MemAddr = ALUOut;
    assign MemWdata = rs2_data;
    assign rd_data = MemtoReg ? MemRdata : ALUOut;
    assign PCA = PCAsrc ? imm : {{(`XLEN-3){1'b0}}, 3'h4};
    assign PCB = PCBsrc ? rs1_data : pc;

    import "DPI-C" function bit check_finsih(input int finish_flag);
    always @(*) begin
        if(check_finsih(instr)) begin  //instr == ebreak.
            $display("\n----------EBREAK: HIT !!%s!! TRAP!!---------------\n", ~|u_RegFile.rf[10] ? "GOOD":"BAD");
            $finish;
        end
    end
endmodule
