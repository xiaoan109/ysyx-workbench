`include "defines.v"
module CPU_top(
        input clk,
        input rst
    );

    wire [`PC_DW-1:0] next_pc;
    wire [`PC_DW-1:0] pc;
    wire [`INST_DW-1:0] instr;
    // RegFile
    wire [`REG_AW-1:0] rf_raddr1;
    wire [`REG_AW-1:0] rf_raddr2;
    wire [`REG_AW-1:0] rf_waddr;
    wire rf_wen;
    wire rf_wr_sel;
    wire [`REG_DW-1:0] rf_wdata;
    wire [`REG_DW-1:0] rf_rdata1;
    wire [`REG_DW-1:0] rf_rdata2;
    // Immediate Number
    wire [`XLEN-1:0] imm;
    // Memory Access
    wire mem_wen;
    wire [2:0] mem_wr_sel;
    wire [`XLEN-1:0] data_mem_out; // dmem rdata after byte sel
    wire [`XLEN-1:0] data_mem_in; // dmem wdata
    wire [`XLEN-1:0] data_mem_addr;
    wire data_mem_we;
    wire [2:0] data_mem_op;
    // Branch
    wire [2:0] branch;
    // ALU
    wire alu_a_sel;
    wire [1:0] alu_b_sel;
    wire [`XLEN-1:0] alu_a;
    wire [`XLEN-1:0] alu_b;
    wire [3:0] alu_ctrl;
    wire [`XLEN-1:0] alu_out;
    // PC
    wire pc_a_sel;
    wire pc_b_sel;
    wire [`XLEN-1:0] pc_a;
    wire [`XLEN-1:0] pc_b;
    assign next_pc = pc_a + pc_b;

    IFU u_IFU(
            .clk(clk),
            .rst(rst),
            .next_pc(next_pc),
            .pc(pc),
            .instr(instr)
        );

    IDU u_IDU(
            .instr(instr),
            .rf_raddr1(rf_raddr1),
            .rf_raddr2(rf_raddr2),
            .rf_waddr(rf_waddr),
            .imm(imm),
            .alu_a_sel(alu_a_sel),
            .alu_b_sel(alu_b_sel),
            .alu_ctrl(alu_ctrl),
            .rf_wen(rf_wen),
            .rf_wr_sel(rf_wr_sel),
            .mem_wen(mem_wen),
            .mem_wr_sel(mem_wr_sel),
            .branch(branch)
        );

    EXU u_EXU(
            .alu_a(alu_a),
            .alu_b(alu_b),
            .alu_ctrl(alu_ctrl),
            .branch(branch),
            .alu_out(alu_out),
            .pc_a_sel(pc_a_sel),
            .pc_b_sel(pc_b_sel)
        );

    // TODO:  LSU

    RegisterFile #(.ADDR_WIDTH(`REG_AW), .DATA_WIDTH(`REG_DW)) u_RegFile(
                     .clk(clk),
                     .wdata(rf_wdata),
                     .waddr(rf_waddr),
                     .wen(rf_wen),
                     .raddr1(rf_raddr1),
                     .raddr2(rf_raddr2),
                     .rdata1(rf_rdata1),
                     .rdata2(rf_rdata2)
                 );

    //alu sel
    assign alu_a = alu_a_sel ? pc : rf_rdata1;
    MuxKey #(3, 2, `XLEN) u_alu_b_sel (alu_b, alu_b_sel, {
                                           2'b00, rf_rdata2,
                                           2'b01, {{(`XLEN-3){1'b0}}, 3'h4},
                                           2'b10, imm
                                       });
    //TODO
    assign data_mem_out = 0;
    assign rf_wdata = rf_wr_sel ? data_mem_out : alu_out;
    assign pc_a = pc_a_sel ? imm : {{(`XLEN-3){1'b0}}, 3'h4};
    assign pc_b = pc_b_sel ? rf_rdata1 : pc;
endmodule
