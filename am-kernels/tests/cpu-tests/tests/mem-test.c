#include "trap.h"


void mem_write_test(uint8_t *start, uint8_t *end, int access_width) {
  uint8_t *addr = start;
  while (addr < end) {
    switch (access_width) {
      case 8:
        *(uint8_t *)addr = (uint8_t)((uintptr_t)addr & 0xFF);
        addr += 1;
        break;
      case 16:
        *(uint16_t *)addr = (uint16_t)((uintptr_t)addr & 0xFFFF);
        addr += 2;
        break;
      case 32:
        *(uint32_t *)addr = (uint32_t)((uintptr_t)addr & 0xFFFFFFFF);
        addr += 4;
        break;
      case 64:
        *(uint64_t *)addr = (uint64_t)((uintptr_t)addr & 0xFFFFFFFFFFFFFFFF);
        addr += 8;
        break;
    }
  }
}

void mem_read_verify(uint8_t *start, uint8_t *end, int access_width) {
  uint8_t *addr = start;
  while (addr < end) {
    switch (access_width) {
      case 8:
        check(*(uint8_t *)addr == (uint8_t)((uintptr_t)addr & 0xFF));
        addr += 1;
        break;
      case 16:
        check(*(uint16_t *)addr == (uint16_t)((uintptr_t)addr & 0xFFFF));
        addr += 4;
        break;
      case 32:
        check(*(uint32_t *)addr == (uint32_t)((uintptr_t)addr & 0xFFFFFFFF));
        addr += 4;
        break;
      case 64:
        check(*(uint64_t *)addr == (uint64_t)((uintptr_t)addr & 0xFFFFFFFFFFFFFFFF));
        addr += 8;
        break;
    }
  }
}

int main() {
  // printf("Starting memory test...\n");

  // uint8_t *psram_start = (uint8_t *)&_psram_start;
  // uint8_t *psram_end = (uint8_t *)&_psram_end;
  // extern char _sdram_start, _sdram_end;  
  // uint8_t *sdram_start = (uint8_t *)&_sdram_start;
  // uint8_t *test_end = (uint8_t *)((uintptr_t)&_sdram_start + 4 * 1024);
  // uint8_t *test_start = (uint8_t *)((uintptr_t)&_sdram_end - 4 * 1024);
  // uint8_t *sdram_end = (uint8_t *)&_sdram_end;
  // uint8_t *chiplink_mem_start = (uint8_t *)0xc0000000;
  // uint8_t *chiplink_mem_end = (uint8_t *)(0xc0000000 + 4 * 1024);

  // printf("Testing memory range: %p - %p\n", heap_start, heap_end);

  // 测试 8 位访问
  // printf("Testing 8-bit access...\n");
  // mem_write_test(chiplink_mem_start, chiplink_mem_end, 8);
  // mem_read_verify(chiplink_mem_start, chiplink_mem_end, 8);

  // mem_write_test(test_start, sdram_end, 8);
  // mem_read_verify(test_start, sdram_end, 8);

  // 测试 16 位访问
  // printf("Testing 16-bit access...\n");
 
  // mem_write_test(sdram_start, test_end, 16);
  // mem_read_verify(sdram_start, test_end, 16);

  // mem_write_test(test_start, sdram_end, 16);
  // mem_read_verify(test_start, sdram_end, 16);

  // 测试 32 位访问
  // printf("Testing 32-bit access...\n");
  // mem_write_test(sdram_start, test_end, 32);
  // mem_read_verify(sdram_start, test_end, 32);

  // mem_write_test(test_start, sdram_end, 32);
  // mem_read_verify(test_start, sdram_end, 32);

  // 测试 64 位访问
  // printf("Testing 64-bit access...\n");
  // mem_write_test(heap_start, psram_end, 64);
  // mem_read_verify(heap_start, psram_end, 64);
  // mem_write_test(sdram_start, test_end, 64);
  // mem_read_verify(sdram_start, test_end, 64);

  // mem_write_test(test_start, sdram_end, 64);
  // mem_read_verify(test_start, sdram_end, 64);

  // printf("Memory test completed.\n");
  return 0;
}


