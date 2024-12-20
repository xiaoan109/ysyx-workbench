module sdram_32mx32(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);

sdram_32mx16 u0_sdram_32mx16(
  .clk   (clk),
  .cke   (cke),
  .cs    (cs ),
  .ras   (ras),
  .cas   (cas),
  .we    (we ),
  .a     (a  ),
  .ba    (ba ),
  .dqm   (dqm[1:0]),
  .dq    (dq[15:0] )
);

sdram_32mx16 u1_sdram_32mx16(
  .clk   (clk),
  .cke   (cke),
  .cs    (cs ),
  .ras   (ras),
  .cas   (cas),
  .we    (we ),
  .a     (a  ),
  .ba    (ba ),
  .dqm   (dqm[3:2]),
  .dq    (dq[31:16])
);

endmodule