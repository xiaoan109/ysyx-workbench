#ifndef NPC_H__
#define NPC_H__

#include <klib-macros.h>
#include <riscv/riscv.h>


#define UART16550       0x10000000
#define UART_TX         UART16550 + 0x0
#define CLINT           0x02000000

extern char _mrom_start;
#define MROM_SIZE (4 * 1024)
#define MROM_END  ((uintptr_t)&_mrom_start + MROM_SIZE)

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
