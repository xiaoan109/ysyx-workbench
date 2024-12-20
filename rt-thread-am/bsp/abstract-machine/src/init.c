#include <am.h>
#include <rtthread.h>
#include <klib.h>
#include <klib-macros.h>

#define AM_APPS_HEAP_SIZE  0x2000000
#define RT_HW_HEAP_BEGIN heap.start
#define RT_HW_HEAP_END heap.end

Area am_apps_heap = {}, am_apps_data = {}, am_apps_bss = {};
uint8_t * am_apps_data_content = NULL;

void rt_hw_board_init() {
  int rt_hw_uart_init(void);
  rt_hw_uart_init();

#ifdef RT_USING_HEAP
  /* initialize memory system */
  rt_system_heap_init(RT_HW_HEAP_BEGIN, RT_HW_HEAP_END);
#endif

  uint32_t size = AM_APPS_HEAP_SIZE;
  void *p = NULL;
  for (; p == NULL && size != 0; size /= 2) { p = rt_malloc(size); }
  am_apps_heap = RANGE(p, p + size);

  extern char __am_apps_data_start, __am_apps_data_end;
  extern char __am_apps_bss_start, __am_apps_bss_end;
  am_apps_data = RANGE(&__am_apps_data_start, &__am_apps_data_end);
  am_apps_bss  = RANGE(&__am_apps_bss_start,  &__am_apps_bss_end);
  printf("am-apps.data.size = %ld, am-apps.bss.size = %ld\n",
      am_apps_data.end - am_apps_data.start, am_apps_bss.end - am_apps_bss.start);

  uint32_t data_size = am_apps_data.end - am_apps_data.start;
  if (data_size != 0) {
    am_apps_data_content = rt_malloc(data_size);
    assert(am_apps_data_content != NULL);
  }
  memcpy(am_apps_data_content, am_apps_data.start, data_size);

#ifdef RT_USING_CONSOLE
  /* set console device */
  rt_console_set_device("uart");
#endif /* RT_USING_CONSOLE */

#ifdef RT_USING_COMPONENTS_INIT
  rt_components_board_init();
#endif

#ifdef RT_USING_HEAP
  rt_kprintf("heap: [0x%08x - 0x%08x]\n", (rt_ubase_t) RT_HW_HEAP_BEGIN, (rt_ubase_t) RT_HW_HEAP_END);
#endif
}

int main() {
  ioe_init();
#ifdef __ISA_NATIVE__
  // trigger the real initialization of IOE to
  // perform SDL initialization int this main thread with large stack
  io_read(AM_TIMER_CONFIG);
#endif
  extern void __am_cte_init();
  __am_cte_init();
  extern int entry(void);
  entry();
  return 0;
}
