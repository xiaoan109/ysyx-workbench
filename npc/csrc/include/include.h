#ifndef _INCLUDE_H_
#define _INCLUDE_H_

#ifdef YSYXSOC
#include <VysyxSoCFull.h>
#else
#include <Vtop.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <macro.h>

#ifdef YSYXSOC
#define INST_START 0x30000000
#else
#define INST_START 0x80000000
#endif

#define PMEM_START 0x80000000
#define PMEM_END   0x87ffffff
#define PMEM_MSIZE (PMEM_END+1-PMEM_START)

#define MROM_START 0x20000000
#define MROM_END   0x20000fff
#define MROM_MSIZE (MROM_END+1-MROM_START)


#define FLASH_START 0x30000000
#define FLASH_END   0x3fffffff
#define FLASH_MSIZE (FLASH_END+1-FLASH_START)

#define PSRAM_START 0x80000000
#define PSRAM_END   0x9fffffff
#define PSRAM_MSIZE (PSRAM_END+1-PSRAM_START)


// #define DIFFTEST_ON  1

typedef struct {
  uint32_t x[32];
  uint32_t pc;
  uint32_t csr[4];
} regfile;

uint8_t* guest_to_host(uint32_t paddr);
// uint32_t host_to_guest(uint8_t *haddr);
uint32_t _pmem_read(uint32_t addr, int len);
void _pmem_write(uint32_t addr, uint32_t data, int len);
uint32_t _mrom_read(uint32_t addr, int len);
void _mrom_write(uint32_t addr, uint32_t data, int len);
void npc_init(int argc, char *argv[]);
void print_regs(regfile *ref, regfile *dut);
bool checkregs(regfile *ref, regfile *dut);
regfile pack_dut_regfile(uint32_t *dut_reg, uint32_t pc, uint32_t *dut_csr);

#ifdef DIFFTEST_ON
void difftest_init(char *ref_so_file, long img_size);
bool difftest_check();
void difftest_step();
#endif

uint64_t get_time();

#endif