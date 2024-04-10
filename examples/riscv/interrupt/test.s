# =============================================================
#
#  Copyright (c) 2021 Simon Southwell. All rights reserved.
#
#  Date: 5th August 2021
#
#  Test program to test external interrupts
#
#  This file is part of the base RISC-V instruction set simulator
#  (rv32_cpu).
#
#  This code is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This code is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this code. If not, see <http://www.gnu.org/licenses/>.
#
# =============================================================

        .file   "test.s"
        .text
        .org 0

        .equ     CAUSE_EXT_INT,        0x8000000b
        .equ     HALT_ADDR,            0x00000040
        .equ     MSTATUS_MIE_BIT_MASK, 0x00000008
        .equ     MIE_MEIE_BIT_MASK,    0x00000800
        .equ     INT_ADDR,             0xaffffffc

# Program reset point
_start: .global _start
        .global main

         # Jump to reset code
         jal      reset_vector
# Trap vector
trap_vector:
         csrr    t5, mcause
         li      t6, CAUSE_EXT_INT
         bne     t5, t6, trap_end
         # Clear the IRQ
         sw      zero, 0(t1)
         li      gp, 2
         mret
trap_end:
         j       halt

# HALT location
         .org HALT_ADDR
halt:
         jal     halt

# Reset routine
reset_vector:
         li      ra,0
         li      sp,0
         li      gp,0
         li      tp,0
         li      t0,0
         li      t1,0
         li      t2,0
         li      s0,0
         li      s1,0
         li      a0,0
         li      a1,0
         li      a2,0
         li      a3,0
         li      a4,0
         li      a5,0
         li      a6,0
         li      a7,0
         li      s2,0
         li      s3,0
         li      s4,0
         li      s5,0
         li      s6,0
         li      s7,0
         li      s8,0
         li      s9,0
         li      s10,0
         li      s11,0
         li      t3,0
         li      t4,0
         li      t5,0
         li      t6,0
         la      t0, trap_vector
         csrw    mtvec, t0
         la      t0, main
         csrw    mepc, t0
         mret

# Main test code
main:
         li     gp, 1
         csrr   t1, mstatus
         # Set MIE (machine global interrupt enable) in mstatus
         ori    t1, t1, MSTATUS_MIE_BIT_MASK
         csrw   mstatus, t1
         # Set MEIP (machine external interrupt enable) in mie
         csrr   t1, mie
         li     t2, MIE_MEIE_BIT_MASK
         or     t1, t1, t2
         csrw   mie, t1
         # Set the IRQ
         la     t1, INT_ADDR
         li     t2, 1
         # This instruction should cause an interrupt on this
         # or the next instruction (ISS executable versus co-simulation).
         sw     t2, 0(t1)
         nop
         # Check the interrupt was processed (gp set to 2)
         li     t6, 2
         bne    gp, t6, fail
         beq    zero, zero, pass
         unimp

# Fail routine (after riscv-test-env standard)
fail:
         beqz gp, fail
         sll gp, gp, 1
         or gp, gp, 1
         li a7, 93
         mv a0, gp
         ecall
         
# Pass routine (after riscv-test-env standard)
pass:
         li gp, 1
         li a7, 93
         li a0, 0
         ecall
