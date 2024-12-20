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

#ifndef __RISCV32_REG_H__
#define __RISCV32_REG_H__

#include <common.h>

static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < 32));
  return idx;
}

#define gpr(idx) cpu.gpr[check_reg_idx(idx)]

static inline const char* reg_name(int idx, int width) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

#define MSTATUS 0x300
#define MTVEC   0x305
#define MEPC    0x341
#define MCAUSE  0x342

static inline int check_csr_idx(int idx) {
  // input width of idx is 12bit, so it is in [0,0xFFF].
  IFDEF(CONFIG_RT_CHECK, assert(idx == 0x300 || idx == 0x305 || idx == 0x341 || idx == 0x342));
  switch (idx)
  {
    case MSTATUS: idx = 0; break;  // mstatus: 0x300 -> 0
    case MTVEC  : idx = 1; break;  // mtvec  : 0x305 -> 1
    case MEPC   : idx = 2; break;  // mepc   : 0x341 -> 2
    case MCAUSE : idx = 3; break;  // mcause : 0x342 -> 3
  }
  return idx;
}

#define csr(idx) (cpu.csr[check_csr_idx(idx)])

#endif
