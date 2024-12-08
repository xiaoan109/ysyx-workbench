#include "include/include.h"
#include "verilated_dpi.h"

static uint64_t us;
extern uint32_t dut_pc;
extern bool dut_status;

IFDEF(DIFFTEST_ON, extern bool is_skip_ref);

extern bool rst_n_sync;
extern "C" void check_rst(svBit rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" svBit check_finish(int instr){
  if(instr == 0x100073 && dut_status == 1) //ebreak;
    return 1;
  else 
    return 0;
}

extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, const svBitVecVal* wmask, svBit wen){
  IFDEF(MTRACE_ON, if(wen) printf("waddr = 0x%08x,wdata = 0x%08x,wmask = 0x%x\n", waddr,wdata,*wmask));
  waddr = waddr & ~0x3u;  //clear low 2bit for 4byte align.
  if (waddr == 0xa0000000 + 0x0000000 && wen){ //UART
    IFDEF(DIFFTEST_ON, is_skip_ref = true);
    if(*wmask) {
      uint8_t ch = (uint8_t)(wdata & 0xff);
      putc(ch, stderr);
    }
    return;
  }

  if(wen) {
    switch (*wmask) {
      case 1:   _pmem_write(waddr, wdata, 1); break; // 0001, 1byte.
      case 3:   _pmem_write(waddr, wdata, 2); break; // 0011, 2byte.
      case 15:  _pmem_write(waddr, wdata, 4); break; // 1111, 4byte.
      default:  break;
    }
  }
}

extern "C" void pmem_read(uint32_t raddr,uint32_t *rdata, svBit ren){
  raddr = raddr & ~0x3u;  //clear low 2bit for 4byte align.
  if (raddr == 0xa0000000 + 0x0002000 && ren){ //TIMER
    IFDEF(DIFFTEST_ON, is_skip_ref = true);
    us = get_time();
    *rdata = (uint32_t)us;
  }
  else if (raddr == 0xa0000000 + 0x0002000 + 0x4 && ren){ //TIMER
    IFDEF(DIFFTEST_ON, is_skip_ref = true);
    *rdata = (uint32_t)(us >> 32);
  }
  else if (ren && raddr>=PMEM_START && raddr<=PMEM_END){
    *rdata = _pmem_read(raddr,4);
    IFDEF(MTRACE_ON, printf("raddr = 0x%08x,rdata = 0x%08x\n",raddr,*rdata));
  }
  else //avoid latch.
    *rdata = 0;
}

extern uint32_t *dut_reg;
extern uint32_t dut_pc;
extern uint32_t *dut_csr;
extern bool dut_status;

extern "C" void set_reg_ptr(const svOpenArrayHandle r) {
  dut_reg = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void set_csr_ptr(const svOpenArrayHandle r) {
  dut_csr = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
  
}

extern "C" void diff_read_pc(uint32_t rtl_pc){
  dut_pc = rtl_pc;
}

extern "C" void diff_read_status(svBit rtl_status){
  dut_status = rtl_status;
}

extern "C" void difftest_skip(){
 IFDEF(DIFFTEST_ON, is_skip_ref = true);
}

// SOC
extern "C" void flash_read(int32_t addr, int32_t *data) { assert(0); }
extern "C" void mrom_read(int32_t addr, int32_t *data) { 
  // assert(0);
  // *data = 0x100073;
  addr = addr & ~0x3u;  //clear low 2bit for 4byte align.
  *data = _pmem_read(addr, 4);
}


