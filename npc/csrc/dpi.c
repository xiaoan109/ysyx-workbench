#include "verilated_dpi.h"
#include <memory/paddr.h>

extern "C" svBit check_finsih(int ins){
  if(ins == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

extern "C" void rtl_pmem_write(int waddr, int wdata, char wmask){
  //printf("waddr = 0x%lx,wdata = 0x%lx,wmask = 0x%x\n",waddr,wdata,wmask);
  //waddr = waddr & ~0x3ul;  //clear low 2bit for 4byte align.
  switch (wmask)
  {
    case 1:   paddr_write(waddr, wdata, 1); break; // 0000_0001, 1byte.
    case 3:   paddr_write(waddr, wdata, 2); break; // 0000_0011, 2byte.
    case 15:  paddr_write(waddr, wdata, 4); break; // 0000_1111, 4byte.
    default:  break;
  }
}

extern "C" void rtl_pmem_read(int raddr,int *rdata){
  //printf("ren = %d, raddr = 0x%08lx,rdata = 0x%016lx\n",ren,raddr,*rdata);
  //raddr = raddr & ~0x3ul;  //clear low 2bit for 4byte align.
  if (raddr>=PMEM_LEFT && raddr<=PMEM_RIGHT){
    *rdata = paddr_read(raddr,4);
  }
  else //avoid latch.
    *rdata = 0;
}