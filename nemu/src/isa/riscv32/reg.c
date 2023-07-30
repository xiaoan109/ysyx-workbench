/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  printf("32 General Registers:\n");
  for(int i = 0; i < 32; i++) {
    printf(ANSI_FG_GREEN"%-3s: "ANSI_FG_MAGENTA FMT_WORD" "ANSI_NONE, regs[i], cpu.gpr[i]);
    if(i%4 == 3) {
      printf("\n");
    }
  }
  printf("Program Counter:\n");
  printf(ANSI_FG_RED"%-3s: "ANSI_FG_MAGENTA FMT_WORD ANSI_NONE"\n", "$pc", cpu.pc);
}

word_t isa_reg_str2val(const char *s, bool *success) {
    char tmp[3] = {s[1], s[2]};
  for (int i = 0; i < 32; i++) {
    if(!strcmp(tmp, regs[i])) {
      *success = true;
      return cpu.gpr[i];
    }
  }
  if(!strcmp(tmp, "pc")) {
    *success = true;
    return cpu.pc;
  }
  Log("Register not found!");
  *success = false;
  return 0;
}
