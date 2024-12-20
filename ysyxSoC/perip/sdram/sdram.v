module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [13:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);
wire [2:0] command = {ras,cas,we};
reg ras_u0 ;
reg cas_u0 ;
reg we_u0  ;
reg ras_u1 ;
reg cas_u1 ;
reg we_u1  ;

always @(*) begin
  case(command)
    3'b000,3'b111:begin
      {ras_u0,cas_u0,we_u0} = command;
      {ras_u1,cas_u1,we_u1} = command;
    end
    default:begin
      {ras_u0,cas_u0,we_u0} = !a[13] ? command : 3'b111;
      {ras_u1,cas_u1,we_u1} =  a[13] ? command : 3'b111;
    end
  endcase
end

sdram_32mx32 u0_sdram_32mx32(
  .clk   (clk),
  .cke   (cke),
  .cs    (cs ),
  .ras   (ras_u0),
  .cas   (cas_u0),
  .we    (we_u0 ),
  .a     (a[12:0]  ),
  .ba    (ba ),
  .dqm   (dqm),
  .dq    (dq)
);

sdram_32mx32 u1_sdram_32mx32(
  .clk   (clk),
  .cke   (cke),
  .cs    (cs ),
  .ras   (ras_u1),
  .cas   (cas_u1),
  .we    (we_u1 ),
  .a     (a[12:0]  ),
  .ba    (ba ),
  .dqm   (dqm),
  .dq    (dq)
);

endmodule