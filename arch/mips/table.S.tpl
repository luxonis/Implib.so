/*
 * Copyright 2022 Yury Gribov
 *
 * The MIT License (MIT)
 *
 * Use of this source code is governed by MIT license that can be
 * found in the LICENSE.txt file.
 */

  .data

  .globl _${lib_suffix}_tramp_table
  .hidden _${lib_suffix}_tramp_table
  .align 4
_${lib_suffix}_tramp_table:
  .zero $table_size

  .text

  .globl _${lib_suffix}_tramp_resolve
  .hidden _${lib_suffix}_tramp_resolve

  .globl _${lib_suffix}_save_regs_and_resolve
  .hidden _${lib_suffix}_save_regs_and_resolve
  .type _${lib_suffix}_save_regs_and_resolve, %function
_${lib_suffix}_save_regs_and_resolve:
  .cfi_startproc

  .set noreorder
  .cpload $$25
  .set nomacro
  .set noat

  // Slow path which calls dlsym, taken only on first call.
  // Registers are saved acc. to "Procedure Call Standard for the MIPS Architecture".
  // For DWARF directives, read https://www.imperialviolet.org/2017/01/18/cfi.html.

#define PUSH_REG(reg) addiu $$sp, $$sp, -4; .cfi_adjust_cfa_offset 4; sw reg, 4($$sp); .cfi_rel_offset reg, 0
#define POP_REG(reg) addiu $$sp, $$sp, 4; .cfi_adjust_cfa_offset -4; lw reg, 0($$sp); .cfi_restore reg

// dwarf_num = 32 + reg_num
#define PUSH_FREG(reg, dwarf_num) addiu $$sp, $$sp, -4; .cfi_adjust_cfa_offset 4; swc1 reg, 4($$sp); .cfi_rel_offset dwarf_num, 0
#define POP_FREG(reg, dwarf_num) addiu $$sp, $$sp, 4; .cfi_adjust_cfa_offset -4; lwc1 reg, 0($$sp); .cfi_restore dwarf_num

  PUSH_REG($$ra)
  PUSH_REG($$a0)
  PUSH_REG($$a1)
  PUSH_REG($$a2)
  PUSH_REG($$a3)
  PUSH_REG($$a3)  // For alignment

#if 0
  // FIXME: GCC complains about odd FP regs without -modd-spreg
  PUSH_FREG($$f12, 44)
  PUSH_FREG($$f13, 45)
  PUSH_FREG($$f14, 46)
  PUSH_FREG($$f15, 47)
#endif

  move $$a0, $$AT

  lw $$25, %call16(_${lib_suffix}_tramp_resolve)($$gp)
  .reloc  1f, R_MIPS_JALR, _${lib_suffix}_tramp_resolve
1: jalr $$25
  nop

#if 0
  POP_FREG($$f15, 47)
  POP_FREG($$f14, 46)
  POP_FREG($$f13, 45)
  POP_FREG($$f12, 44)
#endif

  POP_REG($$a3)
  POP_REG($$a3)
  POP_REG($$a2)
  POP_REG($$a1)
  POP_REG($$a0)
  POP_REG($$ra)

  jr $$ra
  nop

  .set macro
  .set reorder

  .cfi_endproc
