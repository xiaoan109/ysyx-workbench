#include "include/include.h"

uint32_t *dut_reg = NULL;
uint32_t dut_pc;
uint32_t *dut_csr = NULL;


const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

const char *csrs[] = {
  "mstatus", "mtvec", "mepc", "mcause"
};

bool checkregs(regfile *ref, regfile *dut) {
  if(ref->pc != dut->pc){
    printf("difftest error: ");
    printf("next reg pc is diff: ref = 0x%x, dut = 0x%x\n",ref->pc,dut->pc);
    return false;
  }

  for (int i = 0; i < 32; i++) {
    if(ref->x[i] != dut->x[i]){
      printf("difftest error at nextpc = 0x%x, ",dut->pc);
      printf("reg %s is diff: ref = 0x%x, dut = 0x%x\n",regs[i],ref->x[i],dut->x[i]);
      return false;
    }
  }

  for (int i = 0; i < 4; i++) {
    if(ref->csr[i] != dut->csr[i]){
      printf("difftest error at nextpc = 0x%x, ",dut->pc);
      printf("csr %s is diff: ref = 0x%x, dut = 0x%x\n",csrs[i],ref->csr[i],dut->csr[i]);
      return false;
    }
  }
  return true;
}

void print_regs(regfile *ref, regfile *dut){
  printf("---------------DUT REGS---------------\n");
  printf("$pc = 0x%x\n",dut->pc);
  for (int i = 0; i < 32; i++) {
    printf("%3s = 0x%08x\t",regs[i],dut->x[i]);
    if(i % 4==3) {
      printf("\n");
    }
  }
  for(int i = 0; i < 4; i++){
    printf("%8s = 0x%08x\t",csrs[i],dut->csr[i]);
     if(i % 4==3) {
      printf("\n");
    }
  }

  printf("---------------REF REGS---------------\n");
  printf("$pc = 0x%x\n",ref->pc);
  for (int i = 0; i < 32; i++) {
    printf("%3s = 0x%08x\t",regs[i],ref->x[i]);
    if(i % 4==3) {
      printf("\n");
    }
  }
  for(int i = 0; i < 4; i++){
    printf("%8s = 0x%08x\t",csrs[i],ref->csr[i]);
     if(i % 4==3) {
      printf("\n");
    }
  }
}

regfile pack_dut_regfile(uint32_t *dut_reg,uint32_t pc, uint32_t *dut_csr) {
  regfile dut;
  for (int i = 0; i < 32; i++) {
    dut.x[i] = dut_reg[i];
  }
  dut.pc = pc;
  for (int i = 0; i < 4; i++) {
    dut.csr[i] = dut_csr[i];
  }
  return dut;
}