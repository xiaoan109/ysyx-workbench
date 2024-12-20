#include <am.h>
#include <klib.h>
#include <rtthread.h>

static Context* ev_handler(Event e, Context *c) {
  rt_thread_t current = rt_thread_self();
  Context** from = NULL;
  switch (e.event) {
    case EVENT_YIELD:
      from = (Context**)(((rt_ubase_t*)(current->user_data))[1]);
      Context** to = (Context**)(((rt_ubase_t*)(current->user_data))[0]);
      if(from != 0){
        *from = c;
      }
      c = *to;
      break; 
    case EVENT_IRQ_TIMER://native
    	break;
    default: printf("Unhandled event ID = %d\n", e.event); assert(0);
  }
  return c;
}

void __am_cte_init() {
  cte_init(ev_handler);
}

void rt_hw_context_switch(rt_ubase_t from, rt_ubase_t to) {
  rt_thread_t current = rt_thread_self();
  rt_ubase_t from_to[2] = {to, from};
  rt_ubase_t user_data_bnk = current->user_data;
  current->user_data = (rt_ubase_t)from_to;
  yield();
  current->user_data = user_data_bnk;
}

void rt_hw_context_switch_to(rt_ubase_t to) {
  rt_hw_context_switch(0,to);
}

void rt_hw_context_switch_interrupt(void *context, rt_ubase_t from, rt_ubase_t to, struct rt_thread *to_thread) {
  assert(0);
}

void wrapper_func(void *args) {
  void (*tentry)(void *);   // tentry 函数指针
  // void *parameter;          // 参数
  void (*texit)(void);      // texit 函数指针

  uintptr_t *args_addr = ((uintptr_t *)args) - 3;
  tentry = (void(*)(void *))((uintptr_t)(args_addr[2]));
  texit = (void(*)(void))((uintptr_t)(args_addr[0]));
  tentry((void *)((uintptr_t)(args_addr[1])));
  texit();
}

rt_uint8_t *rt_hw_stack_init(void *tentry, void *parameter, rt_uint8_t *stack_addr, void *texit) {
  uintptr_t stack_end = RT_ALIGN((uintptr_t)stack_addr,sizeof(uintptr_t));
  Area area;
  area.end = (void *)stack_end;
  area.start = (void *)stack_end - FINSH_THREAD_STACK_SIZE;
  Context *c = kcontext(area, wrapper_func, (void *)((Context *)stack_end -1));
  uintptr_t *args_addr = ((uintptr_t *)((Context *)stack_end - 1)) - 3;
  args_addr[0] = ((uintptr_t)texit);
  args_addr[1] = ((uintptr_t)parameter);
  args_addr[2] = ((uintptr_t)tentry);
  return (rt_uint8_t *)c;
}
