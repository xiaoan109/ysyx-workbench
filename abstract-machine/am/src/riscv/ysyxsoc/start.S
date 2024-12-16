.section .bl.f, "ax"
.weak _start
.type _start, @function
_start:
  mv s0, zero

  la a0, _bl_s
  la a1, _bl_s_load
  la a2, _ebl_s
  sub a2, a2, a0
  mv t0, zero
0:
  bgeu t0, a2, 1f
  add t1, a1, t0
  lw t2, 0(t1)
  add t1, a0, t0
  sw t2, 0(t1)
  addi t0, t0, 4
  j 0b
1:

  mv a0, zero
  mv a1, zero
  mv a2, zero
  mv t0, zero
  mv t1, zero
  mv t2, zero
  la ra, _do_bl_ss
  jalr ra

.section .bl.s, "ax"
.globl _do_bl_ss
.type _do_bl_ss, @function
_do_bl_ss:
  la a0, _text
  la a1, _text_load
  la a2, _etext
  jal _bl_ss_load_align4

  la a0, _data
  la a1, _data_load
  la a2, _edata
  jal _bl_ss_load_align4

  la a0, _data_extra
  la a1, _data_extra_load
  la a2, _edata_extra
  jal _bl_ss_load_align4

  la a0, _bss_start
  la a2, _ebss
  sub a2, a2, a0
  beqz a2, 1f
  mv t0, zero
0:
  bgeu t0, a2, 1f
  add t1, a0, t0
  sw zero, 0(t1)
  addi t0, t0, 4
  j 0b
1:

  mv a0, zero
  mv a1, zero
  mv a2, zero
  mv t0, zero
  mv t1, zero
  mv t2, zero
  la sp, _stack_pointer
  la ra, _trm_init
  jalr ra

.globl _bl_ss_load_align4
.type _bl_ss_load_align4, @function
_bl_ss_load_align4:
  sub a2, a2, a0
  beqz a2, 1f
  mv t0, zero
0:
  bgeu t0, a2, 1f
  add t1, a1, t0
  lw t2, 0(t1)
  add t1, a0, t0
  sw t2, 0(t1)
  addi t0, t0, 4
  j 0b
1:

  ret
