#include <stdio.h>
#include <common.h>
#include "svdpi.h"
const char* regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
extern CPU_state cpu;
uint64_t* cpu_gpr = NULL;
void set_gpr_ptr(const svOpenArrayHandle r) {
    cpu_gpr = (uint64_t*)svGetArrayPtr(r);
}

// 一个输出RTL中通用寄存器的值的示例
void dump_gpr() {
    printf("32 General Registers:\n");
    for (int i = 0; i < 32; i++) {
        printf(ANSI_FG_GREEN"%-3s:"ANSI_FG_BLUE FMT_WORD" | "ANSI_NONE, regs[i], (word_t)cpu_gpr[i]);
        if (i % 4 == 3) {
            printf("\n");
        }
    }
    printf("Program Counter:\n");
    printf(ANSI_FG_RED"%-3s:"ANSI_FG_MAGENTA FMT_WORD ANSI_NONE "\n", "$pc", cpu.pc);
}

void set_regfile() {
	for (int i=0; i<32; i++) {
		cpu.gpr[i] = cpu_gpr[i];
	}
}

void set_pc(vaddr_t pc) {
    cpu.pc = pc;
}
