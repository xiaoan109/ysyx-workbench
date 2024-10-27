#include "include/include.h"
#include "verilated_dpi.h"

static uint64_t us;

#ifdef DIFFTEST_ON
extern bool is_skip_ref;
#endif

extern bool rst_n_sync;
extern "C" void check_rst(svBit rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" svBit check_finish(int ins){
  if(ins == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

extern "C" void rtl_pmem_write(uint32_t waddr, uint32_t wdata, uint8_t wmask){
  //printf("waddr = 0x%lx,wdata = 0x%lx,wmask = 0x%x\n",waddr,wdata,wmask);
  //waddr = waddr & ~0x7ull;  //clear low 3bit for 8byte align.

  if (waddr == 0xa0000000 + 0x0000000){ //UART
#ifdef DIFFTEST_ON
    is_skip_ref = true;
#endif
    uint8_t ch = (uint8_t)(wdata & 0xff);
    putc(ch, stderr);
    return;
  }

  switch (wmask)
  {
    case 1:   pmem_write(waddr, wdata, 1); break; // 0000_0001, 1byte.
    case 3:   pmem_write(waddr, wdata, 2); break; // 0000_0011, 2byte.
    case 15:  pmem_write(waddr, wdata, 4); break; // 0000_1111, 4byte.
    default:  break;
  }
}

extern "C" void rtl_pmem_read(uint32_t raddr,uint32_t *rdata, svBit ren){
  //printf("ren = %d, raddr = 0x%08lx,rdata = 0x%016lx\n",ren,raddr,*rdata);
  //raddr = raddr & ~0x7ull;  //clear low 3bit for 8byte align.
  if (raddr == 0xa0000000 + 0x0002000){ //TIMER
#ifdef DIFFTEST_ON
    is_skip_ref = true;
#endif
    us = get_time();
    *rdata = (uint32_t)us;
  }
  else if (raddr == 0xa0000000 + 0x0002000 + 0x4){ //TIMER
#ifdef DIFFTEST_ON
    is_skip_ref = true;
#endif
    *rdata = (uint32_t)(us >> 32);
  }
  else if (ren && raddr>=PMEM_START && raddr<=PMEM_END){
    *rdata = pmem_read(raddr,4);
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
