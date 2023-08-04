`include "defines.v"
module ControlUnit(
        input [6:0] op,
        input [2:0] func3,
        input [6:0] func7,
        output [2:0] ExtOp,
        output RegWr,
        output ALUAsrc,
        output [1:0] ALUBsrc,
        output [3:0] ALUctr,
        output MemtoReg,
        output MemWrite,
        output MemRead,
        output [2:0] MemOP,
        output [2:0] Branch
    );

    //RV32I
    wire is_lui;
    wire is_auipc;
    wire is_jal;
    wire is_jalr;
    wire is_beq;
    wire is_bne;
    wire is_blt;
    wire is_bge;
    wire is_bltu;
    wire is_bgeu;
    wire is_lb;
    wire is_lh;
    wire is_lw;
    wire is_lbu;
    wire is_lhu;
    wire is_sb;
    wire is_sh;
    wire is_sw;
    wire is_addi;
    wire is_slti;
    wire is_sltiu;
    wire is_xori;
    wire is_ori;
    wire is_andi;
    wire is_slli;
    wire is_srli;
    wire is_srai;
    wire is_add;
    wire is_sub;
    wire is_sll;
    wire is_slt;
    wire is_sltu;
    wire is_xor;
    wire is_srl;
    wire is_sra;
    wire is_or;
    wire is_and;

    wire is_u_type;
    wire is_j_type;
    wire is_b_type;
    wire is_r_type;
    wire is_i_type;
    wire is_s_type;

    wire alu_add;
    wire alu_sub;
    wire alu_shift_left;
    wire alu_shift_right_logic;
    wire alu_shift_right_arithmetic;
    wire alu_less_set_signed;
    wire alu_less_set_unsigned;
    wire alu_b_out;
    wire alu_xor;
    wire alu_or;
    wire alu_and;
    wire alu_mul_div_rem;

    //RV32I
    assign is_lui    = (op == 7'h37);
    assign is_auipc  = (op == 7'h17);
    assign is_jal    = (op == 7'h6f);
    assign is_jalr   = (op == 7'h67) & (func3 == 3'h0);
    assign is_beq    = (op == 7'h63) & (func3 == 3'h0);
    assign is_bne    = (op == 7'h63) & (func3 == 3'h1);
    assign is_blt    = (op == 7'h63) & (func3 == 3'h4);
    assign is_bge    = (op == 7'h63) & (func3 == 3'h5);
    assign is_bltu   = (op == 7'h63) & (func3 == 3'h6);
    assign is_bgeu   = (op == 7'h63) & (func3 == 3'h7);
    assign is_lb     = (op == 7'h03) & (func3 == 3'h0);
    assign is_lh     = (op == 7'h03) & (func3 == 3'h1);
    assign is_lw     = (op == 7'h03) & (func3 == 3'h2);
    assign is_lbu    = (op == 7'h03) & (func3 == 3'h4);
    assign is_lhu    = (op == 7'h03) & (func3 == 3'h5);
    assign is_sb     = (op == 7'h23) & (func3 == 3'h0);
    assign is_sh     = (op == 7'h23) & (func3 == 3'h1);
    assign is_sw     = (op == 7'h23) & (func3 == 3'h2);
    assign is_addi   = (op == 7'h13) & (func3 == 3'h0);
    assign is_slti   = (op == 7'h13) & (func3 == 3'h2);
    assign is_sltiu  = (op == 7'h13) & (func3 == 3'h3);
    assign is_xori   = (op == 7'h13) & (func3 == 3'h4);
    assign is_ori    = (op == 7'h13) & (func3 == 3'h6);
    assign is_andi   = (op == 7'h13) & (func3 == 3'h7);
    assign is_slli   = (op == 7'h13) & (func3 == 3'h1) & (func7[6:1] == 6'h00);
    assign is_srli   = (op == 7'h13) & (func3 == 3'h5) & (func7[6:1] == 6'h00);
    assign is_srai   = (op == 7'h13) & (func3 == 3'h5) & (func7[6:1] == 6'h10);
    assign is_add    = (op == 7'h33) & (func3 == 3'h0) & (func7 == 7'h00);
    assign is_sub    = (op == 7'h33) & (func3 == 3'h0) & (func7 == 7'h20);
    assign is_sll    = (op == 7'h33) & (func3 == 3'h1) & (func7 == 7'h00);
    assign is_slt    = (op == 7'h33) & (func3 == 3'h2) & (func7 == 7'h00);
    assign is_sltu   = (op == 7'h33) & (func3 == 3'h3) & (func7 == 7'h00);
    assign is_xor    = (op == 7'h33) & (func3 == 3'h4) & (func7 == 7'h00);
    assign is_srl    = (op == 7'h33) & (func3 == 3'h5) & (func7 == 7'h00);
    assign is_sra    = (op == 7'h33) & (func3 == 3'h5) & (func7 == 7'h20);
    assign is_or     = (op == 7'h33) & (func3 == 3'h6) & (func7 == 7'h00);
    assign is_and    = (op == 7'h33) & (func3 == 3'h7) & (func7 == 7'h00);

    assign is_u_type = is_lui | is_auipc;
    assign is_j_type = is_jal;
    assign is_b_type = is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu;
    assign is_r_type = is_add | is_sub | is_sll | is_slt | is_sltu | is_xor | is_srl | is_sra | is_or | is_and;
    assign is_i_type = is_jalr | is_lb | is_lh | is_lw | is_lbu | is_lhu | is_addi | is_slti | is_sltiu | is_xori | is_ori | is_andi | is_slli | is_srli | is_srai;
    assign is_s_type = is_sb | is_sh | is_sw;

    assign ExtOp = is_i_type ? 3'b000 :
           is_u_type ? 3'b001 :
           is_s_type ? 3'b010 :
           is_b_type ? 3'b011 :
           is_j_type ? 3'b100 : 3'b000;

    assign alu_add = is_auipc | is_addi | is_add | is_jal | is_jalr | is_lb | is_lh | is_lw | is_lbu | is_lhu | is_s_type;
    assign alu_sub = is_sub;
    assign alu_shift_left = is_slli | is_sll;
    assign alu_shift_right_logic = is_srli | is_srl;
    assign alu_shift_right_arithmetic = is_srai | is_sra;
    assign alu_less_set_signed = is_slti | is_slt | is_beq | is_bne | is_blt | is_bge;
    assign alu_less_set_unsigned = is_sltiu | is_sltu | is_bltu | is_bgeu;
    assign alu_b_out = is_lui;
    assign alu_xor = is_xori | is_xor;
    assign alu_or = is_ori | is_or;
    assign alu_and = is_andi | is_and;


    //1 for rs1, 0 for PC
    assign ALUAsrc = is_auipc | is_jal | is_jalr;
    //00 for rs2, 01 for 4, 10 for imm
    assign ALUBsrc = is_r_type | is_b_type ? 2'b00 :
           is_jal | is_jalr ? 2'b01 : 2'b10;
    assign ALUctr = alu_add ? 4'b0000 :
           alu_sub ? 4'b1000 :
           alu_shift_left ? 4'b0001 :
           alu_less_set_signed  ? 4'b0010 :
           alu_less_set_unsigned ? 4'b1010 :
           alu_b_out  ? 4'b0011 :
           alu_xor ? 4'b0100 :
           alu_shift_right_logic ? 4'b0101 :
           alu_shift_right_arithmetic ? 4'b1101 :
           alu_or ? 4'b0110 :
           alu_and ? 4'b0111 :
           4'b0000; //0000 for default alu ctrl


    assign RegWr = ~(is_b_type | is_s_type);
    assign MemtoReg = is_lb | is_lh | is_lw | is_lbu | is_lhu; //whether load mem to rf
    assign MemWrite = is_s_type;
    assign MemRead = is_lb | is_lh | is_lw | is_lbu | is_lhu;
    assign MemOP = is_lb | is_sb ? 3'b000 :
           is_lh | is_sh ? 3'b001 :
           is_lw | is_sw? 3'b010 :
           is_lbu ? 3'b100 :
           is_lhu ? 3'b101 :
           3'b000; //3'b000 for default

    assign Branch = is_jal  ? 3'b001 :
           is_jalr ? 3'b010 :
           is_beq  ? 3'b100 :
           is_bne  ? 3'b101 :
           is_blt  ? 3'b110 :
           is_bge  ? 3'b111 :
           is_bltu ? 3'b110 :
           is_bgeu ? 3'b111 :
           3'b000;

endmodule
