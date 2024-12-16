#include "trap.h"
#define UART_BASE 0x10000000L
#define UART_TX   0x0
void init_uart(uint32_t baud_rate);

int main() {
  // init_uart(115200);
  // printf("Hello, World\n");
  // printf("This is a test program for UART16550\n");
  *(volatile char *)(UART_BASE + UART_TX) = 'A';
  *(volatile char *)(UART_BASE + UART_TX) = '\n';
  return 0;
}