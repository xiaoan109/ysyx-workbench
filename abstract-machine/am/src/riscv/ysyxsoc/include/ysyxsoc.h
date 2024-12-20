#ifndef NPC_H__
#define NPC_H__

#include <klib-macros.h>
#include <riscv/riscv.h>


#define UART16550            0x10000000
#define UART_REG_TX          UART16550 + 0x0
#define UART_REG_LC          UART16550 + 0x3
#define UART_REG_DL1         UART16550 + 0x0 //LSB
#define UART_REG_DL2         UART16550 + 0x1 //MSB
#define UART_REG_LS          UART16550 + 0x5
#define UART_REG_RX          UART16550 + 0x0
#define CLINT                0x02000000
#define SPI                  0x10001000
#define SPI_RX0              SPI + 0x0
#define SPI_RX1              SPI + 0x4
#define SPI_RX2              SPI + 0x8
#define SPI_RX3              SPI + 0xc
#define SPI_TX0              SPI + 0x0
#define SPI_TX1              SPI + 0x4
#define SPI_TX2              SPI + 0x8
#define SPI_TX3              SPI + 0xc
#define SPI_CTRL             SPI + 0x10
#define SPI_DIV              SPI + 0x14
#define SPI_SS               SPI + 0x18
#define PS2_KBD_ADDR         0x10011000
#define PS2_KBD_REG_SCANCODE 0x0
#define VGA_FB_ADDR          0x21000000
#define VGA_CTL_ADDR         0x211FFFF0
#define VGA_SYNC_ADDR        (VGA_CTL_ADDR + 4)

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
