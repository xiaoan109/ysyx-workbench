#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>
#include <string.h>
#include <stdio.h>

#define ysyxsoc_ebreak(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

extern char _heap_start;
extern char _psram_end;
int main(const char *args);

// extern char _mrom_start;
// #define MROM_SIZE (4 * 1024)
// #define MROM_END  ((uintptr_t)&_mrom_start + MROM_SIZE)

extern char _sram_start;
#define SRAM_SIZE (8 * 1024)
#define SRAM_END ((uintptr_t)&_sram_start + SRAM_SIZE)

// extern char _flash_start;
// #define FLASH_SIZE (256 * 1024 * 1024)
// #define FLASH_END ((uintptr_t)&_flash_start + FLASH_SIZE)


Area heap = RANGE(&_heap_start, &_psram_end);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;


void brandShow(){
  int i;
  int index;
  char buf[10];
  uint32_t number;
  uint32_t mvendorid;
  uint32_t marchid;
  asm volatile("csrr %0, mvendorid" : "=r"(mvendorid));
  asm volatile("csrr %0, marchid" : "=r"(marchid));
  for(i = 3;i >= 0;i--){
      putch((char)((mvendorid >> i*8) & 0xFF));
  }
  number = marchid;
  index = 0;
  while (number > 0)
  {
    buf[index++] = (number % 10) + '0';
    number /= 10;
  }
  for(i = index - 1;i >= 0;i--){
    putch(buf[i]);
  }
  putch('\n');
  
}

void init_uart(uint32_t baud_rate) {
  outb(UART_REG_LC, inb(UART_REG_LC) | 0x80);
  uint16_t divisior = 50000000/(16 * baud_rate); // dummy system clock speed
  outb(UART_REG_DL2, divisior >> 8);
  outb(UART_REG_DL1, divisior);
  outb(UART_REG_LC, inb(UART_REG_LC) & (~0x80));
}

void init_spi(uint32_t spi_clock, uint8_t spi_ss, uint8_t char_len, uint8_t tx_neg, uint8_t rx_neg, uint8_t lsb) {
  uint16_t divider = 50000000/(2 * spi_clock) - 1; // dummy system clock speed
  outw(SPI_DIV, divider);
  outb(SPI_SS, spi_ss);
  uint32_t ctrl_reg = 1 << 13 | 0 << 12 | lsb << 11 | tx_neg << 10 | rx_neg << 9 | 0 << 8 | char_len; // ASS: 1, IE: 0
  outl(SPI_CTRL, ctrl_reg);
}

void spi_tx(uint8_t *tx_data, uint8_t len) {
  if(len == 8) {
    outb(SPI_TX0, *tx_data);
  } else if(len == 16) {
    outw(SPI_TX0, *(uint16_t *)tx_data);
  } else if(len == 32) {
    outl(SPI_TX0, *(uint32_t *)tx_data);
  } else if(len == 64) {
    outl(SPI_TX0, *(uint64_t *)tx_data);
    outl(SPI_TX1, *(uint64_t *)tx_data >> 32);
  } else {
    return ; //Only support 8, 16, 32bits
  }
}

void spi_rx(uint8_t *rx_data, uint8_t len) {
  while((inl(SPI_CTRL) & 0x100) == 0x100);
  if(len == 8) {
    *rx_data = inb(SPI_RX0);
  } else if(len == 16) {
    *(uint16_t *)rx_data = inw(SPI_RX0);
  } else if(len == 32) {
    *(uint32_t *)rx_data = inl(SPI_RX0);
  } else if(len == 64) {
    *(uint64_t *)rx_data = (uint64_t)inl(SPI_RX1) << 32 | inl(SPI_RX0);
  } else {
    return ; //Only support 8, 16, 32, 64bits
  }
}

void spi_tx_start() {
  outl(SPI_CTRL, inl(SPI_CTRL) | 0x100);
}

void putch(char ch) {
  while((inb(UART_REG_LS) & 0x20) == 0);
  outb(UART_REG_TX, ch);
}

void halt(int code) {
  ysyxsoc_ebreak(code);

  //should not reach here
  while (1);
}

void _trm_init() {
  init_uart(115200);
  brandShow();
  int ret = main(mainargs);
  halt(ret);
}

