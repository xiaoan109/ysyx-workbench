#include "trap.h"

extern char _heap_end;
int main() {
  for(int i = 0; i < 4*1024; i = i + 1) {
    *(uint8_t *)((uint32_t)&_heap_end + i) = (uint8_t)i;
  }

  for(int i = 0; i < 4*1024; i = i + 1) {
    uint8_t data = *(uint8_t *)((uint32_t)&_heap_end + i);
    check(data == (uint8_t)i);
  }
}