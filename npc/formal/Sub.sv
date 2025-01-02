// Sub.sv
`define FORMAL

module Sub (
  input  [3:0] a,
  input  [3:0] b,
  output [3:0] c
);

  // assign c = a + ~b + (a == 4'd2 ? 1'b0 : 1'b1);
  assign c = a + ~b + 1'b1;

`ifdef FORMAL
  always @(*) begin
    c_assert : assert (c == a - b);
  end
`endif  // FORMAL

endmodule
