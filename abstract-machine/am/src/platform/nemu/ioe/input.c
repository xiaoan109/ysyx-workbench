#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t temp_data = inl(KBD_ADDR);
  kbd->keycode = temp_data & ~KEYDOWN_MASK;
  kbd->keydown = temp_data >= KEYDOWN_MASK;
}
