#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>
#include <string.h>

#define ysyxsoc_ebreak(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

extern char _heap_start;
int main(const char *args);

extern char _mrom_start;
#define MROM_SIZE (4 * 1024)
#define MROM_END  ((uintptr_t)&_mrom_start + MROM_SIZE)

extern char _sram_start;
#define SRAM_SIZE (8 * 1024)
#define SRAM_END ((uintptr_t)&_sram_start + SRAM_SIZE)


Area heap = RANGE(&_heap_start, SRAM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void bootloader(){
  extern char _erodata, _data, _edata, _bstart, _bend;
  char *src = &_erodata;
  char *dst = &_data;
  
  /* ROM has data at end of text; copy it.  */
  while (dst < &_edata)
    *dst++ = *src++;
  
  /* Zero bss.  */
  for (dst = &_bstart; dst< &_bend; dst++)
    *dst = 0;
}

void putch(char ch) {
  outb(UART_TX, ch);
}

void halt(int code) {
  ysyxsoc_ebreak(code);

  //should not reach here
  while (1);
}

void _trm_init() {
  bootloader();
  int ret = main(mainargs);
  halt(ret);
}
