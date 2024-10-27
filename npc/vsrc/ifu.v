`include "defines.v"
module ifu (
  input        [`CPU_WIDTH-1:0]  i_pc   ,
  input                          i_rst_n,
  output       [`INS_WIDTH-1:0]            o_ins   
);

  reg [`CPU_WIDTH-1:0] ins;
  
  import "DPI-C" function void rtl_pmem_read (input int raddr, output int rdata, input bit ren);
  import "DPI-C" function void diff_read_pc (input int rtl_pc);
  always @(*) begin
    rtl_pmem_read (i_pc, ins, i_rst_n);
    diff_read_pc(i_pc);
  end

  assign o_ins = ins;

endmodule
