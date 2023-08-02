`include "defines.v"
import "DPI-C" function void rtl_pmem_read(input int raddr, output int rdata);
module IFU(
        input clk,
        input rst,
        input [`PC_DW-1:0] next_pc,
        output [`PC_DW-1:0] pc,
        output reg [`INST_DW-1:0] instr
    );
    //instruction fetch
    always @(pc) begin
        // $display("@%t, read pmem", $time);
        rtl_pmem_read(pc, instr);
    end
    Reg #(.WIDTH(`PC_DW), .RESET_VAL(`RESET_PC)) u_PC_Reg(
            .clk(clk),
            .rst(rst),
            .din(next_pc),
            .dout(pc),
            .wen(1'b1)
        );
endmodule
