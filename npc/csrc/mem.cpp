#include "include/include.h"

uint8_t pmem[PMEM_MSIZE] = {};
uint8_t mrom[MROM_MSIZE] = {};
uint8_t flash[FLASH_MSIZE] = {};
uint8_t psram[PSRAM_MSIZE] = {};

#ifdef YSYXSOC
uint8_t* guest_to_host(uint32_t paddr) { 
  if(paddr >= MROM_START && paddr <= MROM_END) {
    return mrom + paddr - MROM_START;
  } else if (paddr >= FLASH_START && paddr <= FLASH_END) {
    return flash + paddr - FLASH_START;
  } else if(paddr >= PSRAM_START && paddr <= PSRAM_END){
    return psram + paddr - PSRAM_START;
  } else {
    printf("Invalid Address: 0x%0x\n", paddr);
    assert(0);
    // return pmem + paddr - PMEM_START; 
  }
}
#else
uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - PMEM_START; }
#endif

// uint32_t host_to_guest(uint8_t *haddr) { return haddr - pmem + PMEM_START; }

void _pmem_write(uint32_t addr, uint32_t data, int len) {
  uint8_t * paddr = guest_to_host(addr);
  switch (len) {
    case 1: *(uint8_t  *)paddr = data; return;
    case 2: *(uint16_t *)paddr = data; return;
    case 4: *(uint32_t *)paddr = data; return;
  }
}

uint32_t _pmem_read(uint32_t addr, int len) {
  uint8_t * paddr = (uint8_t*) guest_to_host(addr);
  switch (len) {
    case 1: return *(uint8_t  *)paddr;
    case 2: return *(uint16_t *)paddr;
    case 4: return *(uint32_t *)paddr;
  }
  assert(0);
}

// void prog_flash(bool use_init_file, char *flash_file) {

//   if(use_init_file) {
//     FILE *fp = fopen(flash_file, "rb");
//     if(fp == NULL){
//       printf("Can not open '%s'\n", flash_file);
//       assert(0); 
//     }

//     fseek(fp, 0, SEEK_END); // move cur to end.
//     long size = ftell(fp);

//     printf("The flash_file is %s, size = %ld\n", flash_file, size);

//     // uint32_t main_start_addr = 0x10;
//     // uint32_t main_end_addr = 0x28;
//     fseek(fp, 0x10, SEEK_SET);
//     int ret = fread(guest_to_host(FLASH_START), 0x28 - 0x10 + 0x4, 1, fp); 
//     assert(ret == 1);

//     for(int i = 0; i <= 0x28 - 0x10; i = i + 4) {
//       uint32_t temp = _pmem_read(FLASH_START+i, 4);
//       uint32_t data = ((temp & 0x000000FF) <<24) + ((temp & 0x0000FF00) <<8) + ((temp & 0x00FF0000) >>8) + ((temp & 0xFF000000) >>24);
//       _pmem_write(FLASH_START+i, data, 4);
//     }

//     fclose(fp);
//   } else {
//     for(int i = 0; i < FLASH_MSIZE; i++) {
//       flash[i] = i;
//     }
//   }
// }