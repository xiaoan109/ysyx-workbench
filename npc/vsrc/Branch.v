module Branch(
        input [2:0] Branch,
        input zero,
        input less,
        output PCAsrc,
        output PCBsrc
    );

    wire branch_eq;
    wire branch_neq;
    wire branch_less;
    wire branch_greater;
    wire no_jump;
    wire jump_pc;
    wire jump_reg;

    assign branch_eq = (Branch == 3'b100);
    assign branch_neq = (Branch == 3'b101);
    assign branch_less = (Branch == 3'b110);
    assign branch_greater = (Branch == 3'b111);
    assign no_jump = (Branch == 3'b000);
    assign jump_pc = (Branch == 3'b001);
    assign jump_reg = (Branch == 3'b010);
    //0 for 4, 1 for imm
    assign PCAsrc = jump_pc | jump_reg | (branch_eq & zero) | (branch_neq & ~zero) | (branch_less & less) | (branch_greater & ~less);
    // 0 for pc, 1 for rs1
    assign PCBsrc = jump_reg;


endmodule
