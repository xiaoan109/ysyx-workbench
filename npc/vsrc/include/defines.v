// RISC-V32 XLEN
`define XLEN 32
// Program Counter Width
`define PC_DW `XLEN
// Instruction Width
`define INST_DW `XLEN
// RegisterFile Num
`define REG_NUM 32
// RegisterFile Address Width
`define REG_AW $clog2(`REG_NUM)
// RegisterFile Data Width
`define REG_DW `XLEN
// PC Reset Value
`define RESET_PC 32'h80000000