#include <stdio.h>
#include <common.h>

#define PMEM_LEFT  ((paddr_t)CONFIG_MBASE)
#define PMEM_RIGHT ((paddr_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
#define RESET_VECTOR (PMEM_LEFT + CONFIG_PC_RESET_OFFSET)
// #define MTRACE_ON

uint8_t *pmem = NULL;
void init_mem(char *testcase) {
	pmem = (uint8_t*)malloc(CONFIG_MSIZE); //128MB instruction memory
	Assert(pmem, "Can not allocate pmem!");
	Log("physical memory area [0x%08x, 0x%08x]", CONFIG_MBASE, CONFIG_MBASE+CONFIG_MSIZE-1);
  // int i;
  // for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(pmem[0])); i ++) {
  //   pmem[i] = rand();
  // }
  FILE *fp = fopen(testcase, "r");
  Assert(fp, "Can not open %s!", testcase);
  Log("%s is loaded to pmem", testcase);
  uint32_t *p = (uint32_t *)pmem;
	while(fscanf(fp, "%x", p ++) != EOF);
    fclose(fp);
}

static inline word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    default: assert(0);
  }
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
    default: assert(0);
  }
}
static inline uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }

static inline paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

extern CPU_state cpu;
static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

word_t paddr_read(paddr_t addr, int len) {
#ifdef MTRACE_ON
  Log(ANSI_FG_GREEN "[Read  %d Bytes from addr: " FMT_PADDR "]" ANSI_NONE, len, addr);
#endif
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
#ifdef MTRACE_ON
  Log(ANSI_FG_GREEN "[Write %d Bytes data " FMT_WORD "to   addr: " FMT_PADDR "]" ANSI_NONE, len, data, addr);
#endif
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  out_of_bound(addr);
}

word_t vaddr_ifetch(vaddr_t addr, int len) {
  return paddr_read(addr, len);
}

word_t vaddr_read(vaddr_t addr, int len) {
  return paddr_read(addr, len);
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  paddr_write(addr, len, data);
}

void rtl_pmem_read(int raddr, int *rdata) {
  // 总是读取地址为`raddr & ~0x3u`的4字节返回给`rdata`
  raddr = raddr & ~0x3ull;
  *rdata = paddr_read(raddr, 4);
}
void rtl_pmem_write(int waddr, int wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  // waddr = waddr & ~0x3ull;
  switch((unsigned char)wmask) {
    case 1: paddr_write(waddr, 1, wdata); break;
    case 3: paddr_write(waddr, 2, wdata); break;
    case 15: paddr_write(waddr, 4, wdata); break;
    default: break;
  }
}
