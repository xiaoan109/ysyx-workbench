#include <am.h>
#include <klib.h>

void rt_hw_interrupt_enable() {
  iset(1);
}

void rt_hw_interrupt_disable() {
  iset(0);
}
