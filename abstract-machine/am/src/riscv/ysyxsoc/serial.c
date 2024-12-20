#include <am.h>
#include "ysyxsoc.h"

void __am_uart_rx(AM_UART_RX_T *cfg) {
    if((inb(UART_REG_LS) & 0x1) == 0x1){
        cfg->data = inb(UART_REG_RX);
    }else{
        cfg->data = 0xff;
    }
}