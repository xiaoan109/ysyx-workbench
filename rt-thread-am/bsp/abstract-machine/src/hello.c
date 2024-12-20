#include <klib.h>
#include <rtthread.h>

static int hello() {
  printf("Hello RISC-V!\n");
  return 0;
}
INIT_ENV_EXPORT(hello);
