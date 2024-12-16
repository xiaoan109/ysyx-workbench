#include "trap.h"

extern char _flash_start;
#define FLASH_SIZE (16 * 1024 * 1024)
#define FLASH_END ((uintptr_t)&_flash_start + FLASH_SIZE)

void init_uart(uint32_t baud_rate);
void init_spi(uint32_t spi_clock, uint8_t spi_ss, uint8_t char_len, uint8_t tx_neg, uint8_t rx_neg, uint8_t lsb);
void spi_tx(uint8_t *tx_data, uint8_t len);
void spi_rx(uint8_t *rx_data, uint8_t len);
void spi_tx_start();

uint32_t flash_read(uint32_t addr) {
  addr = addr - (uint32_t)&_flash_start;
  uint8_t tx_data[8];
  uint8_t rx_data[8];
  *(uint64_t *)tx_data = (0x3 << 24 | (uint64_t)addr) << 32;
  spi_tx(tx_data, 64);
  spi_tx_start();
  spi_rx(rx_data, 64);
  return *(uint32_t *)rx_data;
}

int main() {
  init_uart(115200);
  init_spi(2500000, 1 << 0, 64, 1, 0, 0); //TX falling edge, RX rising edge

  // for(int i = 0; i < FLASH_SIZE; i = i + (rand() & ~0x3u)) {
  //   uint32_t data = flash_read((uint32_t)&_flash_start + i);
  //   check((uint8_t)(data>>24) == (uint8_t)i);
  //   check((uint8_t)(data>>16) == (uint8_t)i+1);
  //   check((uint8_t)(data>>8) == (uint8_t)i+2);
  //   check((uint8_t)(data) == (uint8_t)i+3);
  // }


  // uint8_t *addr = (uint8_t *)&_flash_start;
  // for(int i = 0; i < FLASH_SIZE; i= i + rand()) {
  //   check(*(addr+i) == (uint8_t)i);
  // }
  

  // extern char _heap_end;
  // uint32_t main_start_addr = 0x10;
  // uint32_t main_end_addr = 0x28;
  // uint8_t *addr = (uint8_t *)&_heap_end;
  // for(int i = 0; i <= main_end_addr - main_start_addr; i = i + 4) {
  //   uint32_t data = flash_read((uint32_t)&_flash_start + i);
  //   for(int j = 0; j < 4; j++) {
  //     *(addr+j) = data >> (j<<3); //copy char-test from flash to sram
  //   }
  //   addr += 4;
  //   printf("data = 0x%x\n", data);
  // }

  // int jump_addr = (int)&_heap_end;
  // int jump_addr = (int)&_flash_start;
  // asm volatile(
  //   "mv t0, %0\n\t"
  //   "jalr x1, t0"
  //   :
  //   : "r"(jump_addr)
  //   : "t0"
  // );

  // for(int i = 0; i < FLASH_SIZE; i = i + (rand() & ~0x3u)) {
  //   uint32_t data = *(uint32_t *)((uint32_t)&_flash_start + i);
  //   check((uint8_t)(data>>24) == (uint8_t)i);
  //   check((uint8_t)(data>>16) == (uint8_t)i+1);
  //   check((uint8_t)(data>>8) == (uint8_t)i+2);
  //   check((uint8_t)(data) == (uint8_t)i+3);
  // }


  return 0;
}