`include "defines.v"
module ALU(
        input [`XLEN-1:0] ALUA,
        input [`XLEN-1:0] ALUB,
        input [3:0] ALUctr,
        output [`XLEN-1:0] ALUOut,
        output less,
        output zero
    );

    wire arithmetic_logic;
    wire left_right;
    wire unsigned_signed;
    wire sub_add;
    wire [`XLEN-1:0] result;
    wire carry_flag;
    wire carry;
    wire overflow;
    wire [`XLEN-1:0] shift;
    wire [`XLEN-1:0] and_ab;
    wire [`XLEN-1:0] or_ab;
    wire [`XLEN-1:0] xor_ab;
    wire [`XLEN-1:0] ALUB_sub;
    wire [`XLEN-1:0] shift_left;
    wire [`XLEN-1:0] shift_right_logic;
    wire [`XLEN-1:0] shift_right_arithmetic;

    assign sub_add = (ALUctr == 4'b1000 | ALUctr == 4'b0010 | ALUctr == 4'b1010);
    assign arithmetic_logic = (ALUctr == 4'b1101);
    assign left_right = (ALUctr == 4'b0001);
    assign unsigned_signed = (ALUctr == 4'b1010);
    assign ALUB_sub = ~ALUB+1;

    //adder
    assign {carry_flag, result} = sub_add ? ALUA+~ALUB+1 : ALUA+ALUB;
    assign carry = sub_add^carry_flag;
    assign overflow = sub_add ? ((ALUA[`XLEN-1] == ALUB_sub[`XLEN-1]) && (result[`XLEN-1] != ALUA[`XLEN-1])) : ((ALUA[`XLEN-1] == ALUB[`XLEN-1]) && (result[`XLEN-1] != ALUA[`XLEN-1]));
    assign zero = ~(| result);

    //shift
    assign shift_left = ALUA<<ALUB[4:0];
    assign shift_right_logic = ALUA>>ALUB[4:0];
    assign shift_right_arithmetic = $signed(ALUA)>>>ALUB[4:0];

    MuxKey #(.NR_KEY(4), .KEY_LEN(2), .DATA_LEN(`XLEN)) u_shifter (
               .out(shift),
               .key({left_right, arithmetic_logic}),
               .lut({
                        2'b00, shift_right_logic,
                        2'b01, shift_right_arithmetic,
                        2'b10, shift_left,
                        2'b11, shift_left
                    })
           );

    //logic
    assign and_ab = ALUA & ALUB;
    assign or_ab = ALUA | ALUB;
    assign xor_ab = ALUA ^ ALUB;

    //compare
    assign less = unsigned_signed ? sub_add^carry : ALUB == {1'b1, {(`XLEN-1){1'b0}}} ? 1'b0 : result[`XLEN-1]^overflow;

    //out_sel
    MuxKey #(.NR_KEY(11), .KEY_LEN(4), .DATA_LEN(`XLEN)) u_out_sel(
               .out(ALUOut),
               .key(ALUctr),
               .lut({
                        4'b0000, result,
                        4'b1000, result,
                        4'b0001, shift,
                        4'b0101, shift,
                        4'b1101, shift,
                        4'b0010, {{(`XLEN-1){1'b0}}, less},
                        4'b1010, {{(`XLEN-1){1'b0}}, less},
                        4'b0011, ALUB,
                        4'b0100, xor_ab,
                        4'b0110, or_ab,
                        4'b0111, and_ab
                    })
           );



endmodule
