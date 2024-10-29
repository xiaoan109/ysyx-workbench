#ifndef ARCH_H__
#define ARCH_H__

#ifdef __riscv_e
#define GPR_NUM 16
#else
#define GPR_NUM 32
#endif

struct Context {
  // TODO: fix the order of these members to match trap.S
  uintptr_t gpr[GPR_NUM], mcause, mstatus, mepc;
  void *pdir;
};

#ifdef __riscv_e
#define GPR1 gpr[15] // a5
#else
#define GPR1 gpr[17] // a7
#endif

#define GPR2 gpr[0]
#define GPR3 gpr[0]
#define GPR4 gpr[0]
#define GPRx gpr[0]

#endif
