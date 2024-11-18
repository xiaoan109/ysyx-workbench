`include "defines.vh"
module idu_system (
    input  [    `INS_WIDTH-1:7] i_instr, // Bits of signal are not used: 'i_instr'[6:0]
    output [    `CSR_ADDRW-1:0] o_csrsid,
    output                      o_csrsren,
    output [    `REG_ADDRW-1:0] o_rs1id,
    output [    `CPU_WIDTH-1:0] o_imm,
    output [`CSR_OPT_WIDTH-1:0] o_excsropt,
    output                      o_excsrsrc,
    output [    `REG_ADDRW-1:0] o_rdid,
    output                      o_rdwen,
    output [    `CSR_ADDRW-1:0] o_csrdid,
    output                      o_csrdwen
);

  wire [2:0] func3;
  wire [4:0] uimm;

  
  assign o_csrsid = i_instr[31:20];
  assign o_csrdid = i_instr[31:20];
  assign o_rs1id  = i_instr[19:15];
  assign uimm     = i_instr[19:15];
  assign func3    = i_instr[14:12];
  assign o_rdid   = i_instr[11: 7];

  wire csrrw  = (func3 == `FUNC3_CSRRW );
  wire csrrs  = (func3 == `FUNC3_CSRRS );
  wire csrrc  = (func3 == `FUNC3_CSRRC );
  wire csrrwi = (func3 == `FUNC3_CSRRWI);
  wire csrrsi = (func3 == `FUNC3_CSRRSI);
  wire csrrci = (func3 == `FUNC3_CSRRCI);
  wire rdneq0 = |o_rdid ;     // rd id not qual to zero.
  wire rsneq0 = |o_rs1id;     // rs id not qual to zero.

  assign o_csrsren =  ((csrrw | csrrwi) & rdneq0) | (csrrs | csrrsi | csrrc | csrrci);

  assign o_csrdwen =  (csrrw | csrrwi) | (rsneq0 & (csrrs | csrrsi | csrrc | csrrci));

  assign o_rdwen = o_csrsren & (o_rdid!=0);

  assign o_excsropt = func3[1:0];   // please read the riscv-pri and riscv-spec manual, 00 for mret,ecall,ebreak... 01,10,11 for rw/rs/rc.

  assign o_excsrsrc = (csrrwi|csrrsi|csrrci) ? `CSR_SEL_IMM : `CSR_SEL_REG;

  assign o_imm = (o_excsrsrc == `CSR_SEL_IMM) ? {{(`CPU_WIDTH-5){ 1'b0 }} , uimm} : `CPU_WIDTH'b0;
endmodule
