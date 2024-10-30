#include "include/include.h"
#include <dlfcn.h>

#ifdef  DIFFTEST_ON

extern uint32_t *dut_reg;
extern uint32_t dut_pc;
extern uint32_t *dut_csr;

bool is_skip_ref = false;
bool is_skip_ref_r = false;

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void (*ref_difftest_memcpy)(uint32_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint32_t n) = NULL;
void (*ref_difftest_raise_intr)(uint32_t NO) = NULL;

void difftest_init(char *ref_so_file, long img_size) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  if((handle = dlopen(ref_so_file, RTLD_NOW)) == NULL) {  
        printf("dlopen - %sn", dlerror());  
        exit(-1);  
    }  

  assert(handle);

  ref_difftest_memcpy = (void (*)(uint32_t addr, void *buf, size_t n, bool direction))dlsym(handle , "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void *dut, bool direction))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint32_t n))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint32_t NO))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)() = (void (*)())dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  ref_difftest_init();
  ref_difftest_memcpy(PMEM_START,guest_to_host(PMEM_START), img_size, DIFFTEST_TO_REF);

  regfile dut = pack_dut_regfile(dut_reg, INST_START, dut_csr);
  // dut.csr[0] = 0x1800; //TODO: better way to init mstatus before hardware rst?
  ref_difftest_regcpy(&dut, DIFFTEST_TO_REF);
}

bool difftest_check() {
  regfile ref,dut;
  if (is_skip_ref_r) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    // printf("@PC= 0x%x, Skip ref reg copy and reg check!\n", dut_pc);
    dut = pack_dut_regfile(dut_reg, dut_pc, dut_csr);
    ref_difftest_regcpy(&dut, DIFFTEST_TO_REF);
    is_skip_ref_r = false;
    return true;
  }
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
  dut = pack_dut_regfile(dut_reg, dut_pc, dut_csr);
  return checkregs(&ref, &dut);
}

void difftest_step() {
  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    // printf("@PC= 0x%x, Skip ref exec!\n", dut_pc);
    is_skip_ref_r = true;
    is_skip_ref = false;
    return;
  }
  ref_difftest_exec(1);
}

#endif