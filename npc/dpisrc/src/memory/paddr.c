#include <common.h>
#include <memory/host.h>
#include <memory/paddr.h>
#include <stdio.h>
#include <utils.h>
// #define MTRACE_ON

static uint8_t *pmem = NULL;
extern CPU_state cpu;
static uint64_t us;

uint8_t *guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len)
{
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data)
{
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr)
{
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR
        ", " FMT_PADDR "] at pc = " FMT_WORD,
        addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

word_t paddr_read(paddr_t addr, int len)
{
  if (likely(in_pmem(addr)))
    return pmem_read(addr, len);
  if (addr == CONFIG_RTC_MMIO)
  {
    us = get_time();
    return (uint32_t)us;
  }
  if (addr == CONFIG_RTC_MMIO + 4)
    return us >> 32;
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data)
{
  if (likely(in_pmem(addr)))
  {
    pmem_write(addr, len, data);
    return;
  }
  if (addr == CONFIG_SERIAL_MMIO)
  {
    uint8_t ch = (uint8_t)(data & 0xff);
    putc(ch, stderr);
    return;
  }

  out_of_bound(addr);
}

long init_mem(char *testcase)
{
  pmem = (uint8_t *)malloc(CONFIG_MSIZE); // 128MB instruction memory
  Assert(pmem, "Can not allocate pmem!");
  Log("physical memory area [0x%08x, 0x%08x]", CONFIG_MBASE,
      CONFIG_MBASE + CONFIG_MSIZE - 1);
  init_isa();
  if (testcase[0] == '\0')
  {
    Log("No image is given. Use the default build-in image.");
    return 4096;
  }

  FILE *fp = fopen(testcase, "rb");
  Assert(fp, "Can not open '%s'", testcase);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", testcase, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(CONFIG_MBASE), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

void rtl_pmem_read(int raddr, int *rdata)
{
  // 总是读取地址为`raddr & ~0x3u`的4字节返回给`rdata`
  // raddr = raddr & ~0x3ull;
  *rdata = paddr_read(raddr, 4);
#ifdef MTRACE_ON
  Log(ANSI_FG_GREEN " [Read  %d Bytes from addr: " FMT_PADDR "]->" FMT_WORD, 4,
      raddr, *rdata);
#endif
}
void rtl_pmem_write(int waddr, int wdata, char wmask)
{
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  // waddr = waddr & ~0x3ull;
  int len = 0;
  switch ((unsigned char)wmask)
  {
  case 1:
    len = 1;
    break;
  case 3:
    len = 2;
    break;
  case 15:
    len = 4;
    break;
  default:
    return;
  }
  paddr_write(waddr, len, wdata);
#ifdef MTRACE_ON
  Log(ANSI_FG_RED "[Write %d Bytes data " FMT_WORD " to addr: " FMT_PADDR
                  "]->" FMT_WORD,
      len, wdata, waddr, paddr_read(waddr, 4));
#endif
}

void free_mem() { free(pmem); }