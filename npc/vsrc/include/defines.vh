// RISC-V32 XLEN
`define CPU_WIDTH 32
`define INS_WIDTH 32
//Register File
`define REG_COUNT (1<<`REG_ADDRW)
`define REG_ADDRW 5
// PC Reset Value
`ifdef YSYXSOC
`define RESET_PC `CPU_WIDTH'h30000000
`else
`define RESET_PC `CPU_WIDTH'h80000000
`endif

// Max minus value
`define INT_MAX 1<<(`CPU_WIDTH-1)

// opcode -> ins type:
`define TYPE_R          7'b0110011  //R type
`define TYPE_S          7'b0100011  //S type
`define TYPE_B          7'b1100011  //B type
`define TYPE_I          7'b0010011  //I type for addi/slli/srli/srai/xori/ori/andi
`define TYPE_I_LOAD     7'b0000011  //I type for lb/lh/lw/lbu/lhu
`define TYPE_I_JALR     7'b1100111  //I type for jalr
`define TYPE_I_EBRK     7'b1110011  //I type for ecall/ebreak
`define TYPE_U_LUI      7'b0110111  //U type for lui
`define TYPE_U_AUIPC    7'b0010111  //U type for auipc
`define TYPE_J          7'b1101111  //J type for jal
`define TYPE_SYS        7'b1110011  //SYS type for ecall/ebreak/csrrw/csrrs/csrrc

// function3:
`define FUNC3_ADD_SUB           3'b000        //ADDI ADD SUB
`define FUNC3_SLL               3'b001        //SLL SLLI
`define FUNC3_SLT               3'b010        //SLT SLTI
`define FUNC3_SLTU              3'b011        //STLU STLIU
`define FUNC3_XOR               3'b100        //XOR XORI
`define FUNC3_SRL_SRA           3'b101        //SRL SRLI SRA SRAI
`define FUNC3_OR                3'b110        //OR ORI
`define FUNC3_AND               3'b111        //AND ANDI

`define FUNC3_BEQ               3'b000
`define FUNC3_BNE               3'b001
`define FUNC3_BLT               3'b100
`define FUNC3_BGE               3'b101
`define FUNC3_BLTU              3'b110
`define FUNC3_BGEU              3'b111

`define FUNC3_LB_SB             3'b000
`define FUNC3_LH_SH             3'b001
`define FUNC3_LW_SW             3'b010
`define FUNC3_LBU               3'b100
`define FUNC3_LHU               3'b101

// EXU source selection:
`define EXU_SEL_WIDTH   2
`define EXU_SEL_REG     `EXU_SEL_WIDTH'b00
`define EXU_SEL_IMM     `EXU_SEL_WIDTH'b01
`define EXU_SEL_PC4     `EXU_SEL_WIDTH'b10
`define EXU_SEL_PCI     `EXU_SEL_WIDTH'b11

// EXU opreator:
`define EXU_OPT_WIDTH   5
`define EXU_NOP         `EXU_OPT_WIDTH'h0
`define EXU_ADD         `EXU_OPT_WIDTH'h1
`define EXU_SUB         `EXU_OPT_WIDTH'h2
`define EXU_AND         `EXU_OPT_WIDTH'h3
`define EXU_OR          `EXU_OPT_WIDTH'h4
`define EXU_XOR         `EXU_OPT_WIDTH'h5
`define EXU_SLL         `EXU_OPT_WIDTH'h6
`define EXU_SRL         `EXU_OPT_WIDTH'h7
`define EXU_SRA         `EXU_OPT_WIDTH'h8
`define EXU_SLT         `EXU_OPT_WIDTH'h9
`define EXU_SLTU        `EXU_OPT_WIDTH'h10
`define EXU_BEQ         `EXU_OPT_WIDTH'h11
`define EXU_BNE         `EXU_OPT_WIDTH'h12
`define EXU_BLT         `EXU_OPT_WIDTH'h13
`define EXU_BGE         `EXU_OPT_WIDTH'h14
`define EXU_BLTU        `EXU_OPT_WIDTH'h15
`define EXU_BGEU        `EXU_OPT_WIDTH'h16

// ALU opreator:
`define ALU_ADD         `EXU_ADD
`define ALU_SUB         `EXU_SUB   //use for sub,slt,beq,bne,blt,bge 
`define ALU_AND         `EXU_AND
`define ALU_OR          `EXU_OR
`define ALU_XOR         `EXU_XOR
`define ALU_SLL         `EXU_SLL
`define ALU_SRL         `EXU_SRL
`define ALU_SRA         `EXU_SRA
`define ALU_SUBU        `EXU_OPT_WIDTH'h17  //use for sltu,bltu,bgeu

`define LSU_OPT_WIDTH   4
`define LSU_LB          `LSU_OPT_WIDTH'b0000    // 000 for FUNC3_LB_SB, 0 for load
`define LSU_LH          `LSU_OPT_WIDTH'b0010    // 001 for FUNC3_LH_SH, 0 for load
`define LSU_LW          `LSU_OPT_WIDTH'b0100    // 010 for FUNC3_LW_SW, 0 for load
`define LSU_LBU         `LSU_OPT_WIDTH'b1000    // 100 for FUNC3_LBU,   0 for load
`define LSU_LHU         `LSU_OPT_WIDTH'b1010    // 101 for FUNC3_LHU,   0 for load
`define LSU_SB          `LSU_OPT_WIDTH'b0001    // 000 for FUNC3_LB_SB, 1 for store
`define LSU_SH          `LSU_OPT_WIDTH'b0011    // 001 for FUNC3_LH_SH, 1 for store
`define LSU_SW          `LSU_OPT_WIDTH'b0101    // 010 for FUNC3_LW_SW, 1 for store
`define LSU_NOP         `LSU_OPT_WIDTH'b1111    // 1111 for nop!! "lowest bit = 0" <=> "this is an load ins"


// 4. for cpu csr ://////////////////////////////////////////////////////////////////////////////////////////

// csr regfile define:
`define CSR_COUNT       (1<<`CSR_ADDRW)
`define CSR_ADDRW       12
`define ADDR_MSTATUS    `CSR_ADDRW'h300
`define ADDR_MTVEC      `CSR_ADDRW'h305
`define ADDR_MEPC       `CSR_ADDRW'h341
`define ADDR_MCAUSE     `CSR_ADDRW'h342
`define ADDR_MVENDORID  `CSR_ADDRW'hf11
`define ADDR_MARCHID    `CSR_ADDRW'hf12

// csr fun3:
`define FUNC3_ECALL     3'b000  //for ecall
`define FUNC3_CSRRW     3'b001
`define FUNC3_CSRRS     3'b010
`define FUNC3_CSRRC     3'b011
`define FUNC3_CSRRWI    3'b101
`define FUNC3_CSRRSI    3'b110
`define FUNC3_CSRRCI    3'b111

// csr opreator for exu:
`define CSR_OPT_WIDTH   2
`define CSR_NOP         `CSR_OPT_WIDTH'b00
`define CSR_RW          `CSR_OPT_WIDTH'b01
`define CSR_RS          `CSR_OPT_WIDTH'b10
`define CSR_RC          `CSR_OPT_WIDTH'b11

`define CSR_SEL_REG     1'b0
`define CSR_SEL_IMM     1'b1

// intr define:
`define IRQ_ECALL       `CPU_WIDTH'd11


// sram delay
`ifndef SRAM_DELAY
`define SRAM_DELAY      1
`endif

`ifndef MEM_INIT_FILE
`define MEM_INIT_FILE
`endif


// SoC addr
`define CLINT_ADDR	        32'h02000000
`define CLINT_SIZE          32'h10000
`define SRAM_ADDR	          32'h0f000000
`define SRAM_SIZE           32'h1000000
`define UART16550_ADDR	    32'h10000000
`define UART16550_SIZE      32'h1000
`define SPI_ADDR	          32'h10001000
`define SPI_SIZE            32'h1000
`define GPIO_ADDR	          32'h10002000
`define GPIO_SIZE           32'h10
`define PS2_ADDR            32'h10011000
`define PS2_SIZE            32'h8
`define MROM_ADDR	          32'h20000000
`define MROM_SIZE           32'h1000
`define VGA_ADDR	          32'h21000000
`define VGA_SIZE            32'h200000
`define Flash_ADDR	        32'h30000000
`define Flash_SIZE          32'h10000000
`define ChipLink_MMIO_ADDR	32'h40000000
`define ChipLink_MMIO_SIZE  32'h40000000
`define PSRAM_ADDR	        32'h80000000
`define PSRAM_SIZE          32'h20000000
`define SDRAM_ADDR	        32'ha0000000
`define SDRAM_SIZE          32'h20000000
`define ChipLink_MEM_ADDR	  32'hc0000000
`define ChipLink_MEM_SIZE   32'h40000000
// AXI Port
`define S_COUNT              2 //ifu & lsu

`ifdef YSYXSOC
`define M_COUNT              2 //mem & clint
`define MEM_AXI_REGION       9 //PERIP & MEM: m_axi_port1, CLINT: m_axi_port0
`define MEM_BASE_ADDR        {`VGA_ADDR, `PS2_ADDR, `GPIO_ADDR, `SDRAM_ADDR, `PSRAM_ADDR, `SPI_ADDR, `Flash_ADDR, `SRAM_ADDR, `UART16550_ADDR}
`define MEM_ADDR_WIDTH       {$clog2(`VGA_SIZE), $clog2(`PS2_SIZE), $clog2(`GPIO_SIZE), $clog2(`SDRAM_SIZE), $clog2(`PSRAM_SIZE), $clog2(`SPI_SIZE), $clog2(`Flash_SIZE), $clog2(`SRAM_SIZE), $clog2(`UART16550_SIZE)}
`define CLINT_BASE_ADDR      {{(`MEM_AXI_REGION-1){32'b0}}, `CLINT_ADDR}
`define CLINT_ADDR_WIDTH     {{(`MEM_AXI_REGION-1){32'b0}}, $clog2(`CLINT_SIZE)}
`define AXI_MASTER_BASE_ADDR {`MEM_BASE_ADDR, `CLINT_BASE_ADDR}
`define AXI_MASTER_ADDR_WIDTH {`MEM_ADDR_WIDTH, `CLINT_ADDR_WIDTH}
`else
`define M_COUNT              3 //mem & clint & uart
`define MEM_AXI_REGION       1 //PMEM
`define MEM_BASE_ADDR        32'h80000000
`define MEM_ADDR_WIDTH       $clog2(32'h8000000)
`define CLINT_BASE_ADDR      {{(`MEM_AXI_REGION-1){32'b0}}, 32'ha0002000}
`define CLINT_ADDR_WIDTH     {{(`MEM_AXI_REGION-1){32'b0}}, $clog2(32'h1000)}
`define UART_BASE_ADDR       {{(`MEM_AXI_REGION-1){32'b0}}, 32'ha0000000}
`define UART_ADDR_WIDTH      {{(`MEM_AXI_REGION-1){32'b0}}, $clog2(32'h1000)}
`define AXI_MASTER_BASE_ADDR {`MEM_BASE_ADDR, `CLINT_BASE_ADDR, `UART_BASE_ADDR}
`define AXI_MASTER_ADDR_WIDTH {`MEM_ADDR_WIDTH, `CLINT_ADDR_WIDTH, `UART_ADDR_WIDTH}
`endif