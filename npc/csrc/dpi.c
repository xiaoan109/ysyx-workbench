#include "verilated_dpi.h"
#include <memory/paddr.h>

extern bool rst_n_sync;
extern "C" void check_rst(svBit rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" svBit check_finish(int instr){
  if(instr == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

extern "C" void rtl_pmem_write(int waddr, int wdata, char wmask){
  //waddr = waddr & ~0x3ul;  //clear low 2bit for 4byte align.
  switch (wmask)
  {
    case 1:   paddr_write(waddr, 1, wdata); break; // 0000_0001, 1byte.
    case 3:   paddr_write(waddr, 2, wdata); break; // 0000_0011, 2byte.
    case 15:  paddr_write(waddr, 4, wdata); break; // 0000_1111, 4byte.
    default:  break;
  }
}

extern "C" void rtl_pmem_read(int raddr,int *rdata, svBit ren){
  //raddr = raddr & ~0x3ul;  //clear low 2bit for 4byte align.
  if (ren && raddr>=PMEM_LEFT && raddr<=PMEM_RIGHT){
    *rdata = paddr_read(raddr,4);
  }
  else //avoid latch.
    *rdata = 0;
}

extern uint32_t *dut_reg;
extern uint32_t dut_pc;
extern "C" void set_reg_ptr(const svOpenArrayHandle r) {
  dut_reg = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void diff_read_pc(uint32_t rtl_pc){
  dut_pc = rtl_pc;
}