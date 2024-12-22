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
      case 2:   _pmem_write(waddr + 1, wdata>>8, 1); break;  // 0010, 1byte
      case 4:   _pmem_write(waddr + 2, wdata>>16, 1); break;  // 0100, 1byte
      case 8:   _pmem_write(waddr + 3, wdata>>24, 1); break;  // 1000, 1byte
      case 3:   _pmem_write(waddr, wdata, 2); break; // 0011, 2byte.
      case 12:  _pmem_write(waddr + 2, wdata>>16, 2); break; // 1100, 2byte.
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
extern "C" void flash_read(int32_t addr, int32_t *data) {
  addr = FLASH_START + addr; // SPI2FLASH only cares low 24bits i.e. 16MB
  if(addr>=FLASH_START && addr<=FLASH_END) {
    addr = addr & ~0x3u;
    uint32_t temp = _pmem_read(addr, 4);
    // Flash endianness convert
    *data = ((temp & 0x000000FF) <<24) + ((temp & 0x0000FF00) <<8) + ((temp & 0x00FF0000) >>8) + ((temp & 0xFF000000) >>24);
    // printf("flash_read addr: 0x%08x data: 0x%08x\n", addr, temp);
  }
}

extern "C" void mrom_read(int32_t addr, int32_t *data) { 
  // assert(0);
  // *data = 0x100073;
  if(addr>=MROM_START && addr<=MROM_END) {
    addr = addr & ~0x3u;  //clear low 2bit for 4byte align.
    *data = _pmem_read(addr, 4);
  }
}

extern "C" void psram_read(int32_t addr, int32_t *data) {
  addr = PSRAM_START + addr; // SPI2PSRAM only cares low 24bits i.e. 16MB
  if(addr>=PSRAM_START && addr<=PSRAM_END) {
    // addr = addr & ~0x3u;
    *data = _pmem_read(addr, 4);
    // printf("psram_read addr: 0x%08x data: 0x%08x\n", addr, *data);
  }
}

extern "C" void psram_write(int32_t addr, int32_t data, int32_t mask) {
  addr = PSRAM_START + addr; // SPI2FLASH only cares low 24bits i.e. 16MB
  if(addr>=PSRAM_START && addr<=PSRAM_END) {
    // addr = addr & ~0x3u;
    uint32_t wdata = data >> ((8-mask)*4);
    _pmem_write(addr, wdata, mask/2);
    // printf("psram_write addr: 0x%08x data: 0x%08x\n", addr, data);
  }
}


// performance counter
extern uint64_t ifu_pfc_r;
extern uint64_t lsu_pfc_r;
extern uint64_t lsu_pfc_w;
extern uint64_t exu_pfc;
extern uint64_t idu_cal_type;
extern uint64_t idu_mem_type;
extern uint64_t idu_jump_type;
extern uint64_t idu_csr_type;
extern uint8_t current_inst_type;
extern VerilatedContext* contextp;
extern uint64_t timestap_begin;
static uint64_t lsu_begin_time = 0;
extern double lsu_read_delay;
extern double lsu_write_delay;

uint64_t get_sim_time();

extern "C" void axi4_handshake(svBit valid, svBit ready, svBit last, int pfc_type) {
  if(valid && ready && last) {
    switch(pfc_type) {
      case 1: ifu_pfc_r++; break;
      case 2: case 5: lsu_begin_time = get_sim_time(); break;
      case 4: lsu_pfc_w++; lsu_write_delay += (get_sim_time() - lsu_begin_time) / 2.0; break;
      case 6: lsu_pfc_r++; lsu_read_delay += (get_sim_time()- lsu_begin_time) / 2.0; break;
      default: break;
    }
  }
}

extern "C" void exu_finish(svBit valid) {
  if(valid) {
    exu_pfc++;
  }
}

extern "C" void idu_instr_type(svBit valid, int opcode) {
  if(valid) {
    switch(opcode) {
      case 0x33: case 0x13: case 0x37: case 0x17: idu_cal_type++; current_inst_type = 0; break; //include U-type
      case 0x23: case 0x3: idu_mem_type++; current_inst_type = 1; break;
      case 0x63: case 0x67: case 0x6f: idu_jump_type++; current_inst_type = 2; break;
      case 0x73: idu_csr_type++; current_inst_type = 3; break; //include ebreak
    }
  }
}

extern "C" void inst_start(svBit start) {
  if(start && rst_n_sync) timestap_begin = get_sim_time(); 
}


