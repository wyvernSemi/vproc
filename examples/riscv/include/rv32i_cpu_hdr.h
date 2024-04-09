// =========================================================================
//
//  File Name:         rv32i_cpu_hdr.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//    Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the header for local definitions for the rv32i_cpu class
//
//    This file is part of the Zicsr extended RISC-V instruction
//    set simulator (rv32i_cpu).
//
//  Revision History:
//    Date      Version    Description
//    07/2023   2023.??    Updates for supporting FreeRTOS
//    01/2023   2023.01    Released with OSVVM CoSim
//    28th June 2021       Earlier version
//
//  This file is part of OSVVM.
//
//  Copyright (c) 2021 Simon Southwell. 
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
// =========================================================================

#ifndef _RV32I_CPU_HDR_H_
#define _RV32I_CPU_HDR_H_

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include <cstdio>
#include <cstdint>
#include <csignal>

// -------------------------------------------------------------------------
// DEFINES
// -------------------------------------------------------------------------

// --------------------------------
// RISC-V non-specific definitions
//

// Map some signals undefined in windows to linux values
#if defined (_WIN32) || defined (_WIN64)
# define SIGTRAP                                       5
# define SIGHUP                                        1
#endif

#define DISASSEM_STR_SIZE                              100
#define NUM_DISASSEM_BUFS                              6

// General bit position masks
#define MASK_BIT31                                     0x80000000
#define MASK_SIGN_BIT6                                 0x00000020
#define MASK_SIGN_BYTE                                 0x00000080
#define MASK_SIGN_BIT9                                 0x00000100
#define MASK_SIGN_BIT10                                0x00000200
#define MASK_SIGN_BIT12                                0x00000800
#define MASK_SIGN_BIT13                                0x00001000
#define MASK_SIGN_HWORD                                0x00008000
#define MASK_SIGN_BIT17                                0x00010000
#define MASK_SIGN_BIT18                                0x00020000
#define MASK_SIGN_BIT21                                0x00100000
#define MASK_SIGN_BIT32                                MASK_BIT31

// General bit masks
#define MASK_INSTR_ADDR                                0xfffffffc
#define BIT2_MASK                                      0x00000003
#define BIT5_MASK                                      0x0000001f
#define BIT6_MASK                                      0x0000003f
#define BYTE_MASK                                      0x000000ff
#define BIT9_MASK                                      0x000001ff
#define BIT10_MASK                                     0x000003ff
#define BIT12_MASK                                     0x00000fff
#define BIT13_MASK                                     0x00001fff
#define HWORD_MASK                                     0x0000ffff
#define BIT17_MASK                                     0x0001ffff
#define BIT18_MASK                                     0x0003ffff
#define BIT21_MASK                                     0x001fffff
#define WORD_MASK                                      0xffffffff
                                                       
#define MEM_SIZE_BITS                                  32
#define MAXCODEMEM                                     (0x1ULL << MEM_SIZE_BITS)

// Exit code types
#ifndef NO_ERROR
#define NO_ERROR                                       0
#endif
#define USER_ERROR                                     1
#define INSTR_ERROR                                    2
#define INTERNAL_ERROR                                 3

#define RISCV_TEST_ENV_TERMINATE_ADDR                  0x40

// Memory access types
#define MEM_WR_ACCESS_BYTE                             0
#define MEM_WR_ACCESS_HWORD                            1
#define MEM_WR_ACCESS_WORD                             2
#define MEM_WR_ACCESS_INSTR                            3
#define MEM_RD_ACCESS_BYTE                             4
#define MEM_RD_ACCESS_HWORD                            5
#define MEM_RD_ACCESS_WORD                             6
#define MEM_RD_ACCESS_INSTR                            7

#define MEM_NOT_DBG_MASK                               0x0f
#define MEM_DBG_MASK                                   0x10

#define SIGN32_BIT                                     0x80000000U
#define SIGN64_BIT                                     0x8000000000000000L

// External memory callback return values
#define RV32I_EXT_MEM_NOT_PROCESSED                    (-1)

#define RV32_DEFAULT_TCP_PORT                          0xc000

// --------------------------------
// RISC-V specific definitions
//

// Instruction field masks
#define RV32I_MASK_OPCODE                              0x0000007f
#define RV32I_OPCODE_START_BIT                         0

#define RV32I_MASK_32BIT_INSTR                         0x3

#define RV32I_MASK_Rx_RD                               0x00000f80
#define RV32I_MASK_Rx_RS1                              0x000f8000
#define RV32I_MASK_Rx_RS2                              0x01f00000
#define RV32I_Rx_RD_START_BIT                          7
#define RV32I_Rx_RS1_START_BIT                         15
#define RV32I_Rx_RS2_START_BIT                         20

#define RV32I_SHIFT_RSVD_BIT_MASK                      0xbe000000
 
#define RV32I_MASK_FUNCT_3                             0x00007000
#define RV32I_MASK_FUNCT_7                             0xfe000000
#define RV32I_FUNCT_3_START_BIT                        12
#define RV32I_FUNCT_7_START_BIT                        25

#define RV32I_MASK_IMM_SIGN_BIT                        0x80000000
#define RV32I_MASK_IMM_I                               0xfff00000
#define RV32I_MASK_IMM_I_SHAMT                         0x01f
#define RV32I_MASK_IMM_S_4_0                           0x00000f80
#define RV32I_MASK_IMM_S_11_5                          0xfe000000
#define RV32I_MASK_IMM_B_4_1                           0x00000f00
#define RV32I_MASK_IMM_B_10_5                          0x7e000000
#define RV32I_MASK_IMM_B_11                            0x00000080
#define RV32I_MASK_IMM_B_12                            0x80000000
#define RV32I_MASK_IMM_U                               0xfffff000
#define RV32I_MASK_IMM_J_10_1                          0x7fe00000
#define RV32I_MASK_IMM_J_11                            0x00100000
#define RV32I_MASK_IMM_J_19_12                         0x000ff000
#define RV32I_MASK_IMM_J_20                            0x80000000
#define RV32I_IMM_SIGN_BIT                             31
#define RV32I_IMM_I_START_BIT                          20
#define RV32I_IMM_S_4_0_START_BIT                      7
#define RV32I_IMM_S_11_5_START_BIT                     25
#define RV32I_IMM_B_4_1_START_BIT                      8
#define RV32I_IMM_B_10_5_START_BIT                     25
#define RV32I_IMM_B_11_START_BIT                       7
#define RV32I_IMM_B_12_START_BIT                       31
#define RV32I_IMM_U_START_BIT                          12
#define RV32I_IMM_J_10_1_START_BIT                     21
#define RV32I_IMM_J_11_START_BIT                       20
#define RV32I_IMM_J_19_12_START_BIT                    12
#define RV32I_IMM_J_20_START_BIT                       31

// Decode types
#define RV32I_INSTR_ILLEGAL                            (-1)
#define RV32I_INSTR_FMT_R                              0x00
#define RV32I_INSTR_FMT_I                              0x01
#define RV32I_INSTR_FMT_S                              0x02
#define RV32I_INSTR_FMT_B                              0x03
#define RV32I_INSTR_FMT_U                              0x04
#define RV32I_INSTR_FMT_J                              0x05
#define RV32I_INSTR_FMT_R4                             0x06

#define RV32C_INSTR_FMT_R                              0x10
#define RV32C_INSTR_FMT_I                              0x11
#define RV32C_INSTR_FMT_S                              0x12
#define RV32C_INSTR_FMT_B                              0x13
#define RV32C_INSTR_FMT_A                              0x14
#define RV32C_INSTR_FMT_J                              0x15
#define RV32C_INSTR_FMT_SS                             0x16
#define RV32C_INSTR_FMT_IW                             0x17
#define RV32C_INSTR_FMT_L                              0x18

// Trap types                                          
#define RV32I_IADDR_MISALIGNED                         0
#define RV32I_INSTR_ACCESS_FAULT                       1
#define RV32I_ILLEGAL_INSTR                            2
#define RV32I_BREAK_POINT                              3
#define RV32I_LADDR_MISALIGNED                         4
#define RV32I_LOAD_ACCESS_FAULT                        5
#define RV32I_ST_AMO_ADDR_MISALIGNED                   6
#define RV32I_ST_AMO_ACCESS_FAULT                      7
#define RV32I_ENV_CALL_U_MODE                          8
#define RV32I_ENV_CALL_S_MODE                          9
#define RV32I_ENV_CALL_M_MODE                          11
#define RV32I_INSTR_PAGE_FAULT                         12
#define RV32I_LOAD_PAGE_FAULT                          13
#define RV32I_ST_AMO_PAGE_FAULT                        15

//#define RV32_IADDR_ALIGN_MASK                          0x00000003

// SYSTEM intructions' opcode
#define RV32I_SYS_OPCODE                               0x73
                                                       
#define RV32CSR_PRIV_MASK                              0x300
#define RV32CSR_RIV_START_BIT                          8
#define RV32_PRIV_USER                                 0
#define RV32_PRIV_SUPERVISOR                           1
#define RV32_PRIV_HYPERVISOR                           2
#define RV32_PRIV_MACHINE                              3
#define RV32CSR_RW_MASK                                0xc00

// Basic configurations definitions
#ifdef RV32E_EXTENSION
#define RV32I_NUM_OF_REGISTERS                         16
#else
#define RV32I_NUM_OF_REGISTERS                         32
#endif
#define RV32I_NUM_OF_HARTS                             1
#define RV32I_CSR_SPACE_SIZE                           4096
#define RV32I_NUM_PRIMARY_OPCODES                      32
#define RV32I_NUM_SECONDARY_OPCODES                    8
#define RV32I_NUM_TERTIARY_OPCODES                     128
#define RV32I_NUM_SYSTEM_OPCODES                       32
#define RV32I_INT_MEM_WORDS                            (16*1024)

// The RV32I base class has a hardwired MTVEC location since
// since CSR accesses are not supported. Set to riscv-test-env
// trap_vector location (assuming _start at 0x00000000)
#define RV32I_FIXED_MTVEC_ADDR                         0x00000004

// Reset vector (implementation dependent)
#define RV32I_RESET_VECTOR                             0x00000000

// Memory mapped mtime and mtimecmp register offsets 
#define RV32I_RTCLOCK_ADDRESS                          0xafffffe0
#define RV32I_RTCLOCK_CMP_ADDRESS                      0xafffffe8

// FP rounding modes
#define RV32I_RNE                                      0
#define RV32I_RTZ                                      1
#define RV32I_RDN                                      2
#define RV32I_RUP                                      3
#define RV32I_RMM                                      4
#define RV32I_DYN                                      7

// FP flga masks
#define RV32I_NX                                       0x01
#define RV32I_UF                                       0x02
#define RV32I_OF                                       0x04
#define RV32I_DZ                                       0x08
#define RV32I_NV                                       0x10

#define RV32I_QNANF                                    0xffffffff7fc00000UL
#define RV32I_SNANF                                    0xffffffff7f800001UL
#define RV32I_QNAND                                    0x7ff8000000000000UL
#define RV32I_SNAND                                    0x7ff0000000000001UL

// Timing model definitions
#define RV32I_DEFAULT_INSTR_CYCLE_COUNT                1
#define RV32I_JUMP_INSTR_EXTRA_CYCLES                  3
#define RV32I_BRANCH_TAKEN_EXTRA_CYCLES                3
#define RV32I_TRAP_EXTRA_CYCLES                        3

// -------------------------------------------------------------------------
// MACROS
// -------------------------------------------------------------------------

// --------------------------------
// RISC-V non-specific definitions
//

// Define LIBRISCV32_DLL_LINKAGE in windows projects that will link to librv32 as a DLL,
// else leave undefined for projects that compile the source code.

#if (defined(_WIN32) || defined(_WIN64)) && defined (LIBRISCV32_DLL_LINKAGE)

// The DLL build needs to export, whereas those linking to it need import definitions
# ifdef LIBRISCV32_EXPORTS
#  define LIBRISCV32_API                               __declspec(dllexport) 
# else
#  define LIBRISCV32_API                               __declspec(dllimport) 
# endif

#else

# define LIBRISCV32_API

#endif

#if defined( __CYGWIN__) || defined(_WIN32) || defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
  #define SWAP(_ARG)                                   (((_ARG >> 24)&0xff) | ((_ARG >> 8)&0xff00) | ((_ARG << 8)&0xff0000) | ((_ARG << 24)&0xff000000))
  #define SWAPHALF(_ARG)                               (uint32_t)(((_ARG>>8)&0xff) | ((_ARG<<8)&0xff00))
#else
  #define SWAP(_ARG) _ARG
  #define SWAPHALF(_ARG) _ARG
#endif

// Macro to initialise a primary table entry with secondary table.
// Could not get designator on union to work on both visual studio
// and g++, even though available from C99 onwards. So used this
// macro instead.
#define INIT_TBL_WITH_SUBTBL(_a,_b)                    {_a.sub_table=true;_a.ref.p_entry=(_b); _a.p=NULL;}

// Macros to sign extend
#define SIGN_EXT6(_val)                                ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT6)  ? ~BIT6_MASK  : 0)))
#define SIGN_EXT8(_val)                                ((int32_t)((_val) | (((_val) & MASK_SIGN_BYTE)  ? ~BYTE_MASK  : 0)))
#define SIGN_EXT9(_val)                                ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT9)  ? ~BIT9_MASK  : 0)))
#define SIGN_EXT10(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT10) ? ~BIT10_MASK : 0)))
#define SIGN_EXT12(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT12) ? ~BIT12_MASK : 0)))
#define SIGN_EXT13(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT13) ? ~BIT13_MASK : 0)))
#define SIGN_EXT16(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_HWORD) ? ~HWORD_MASK : 0)))
#define SIGN_EXT17(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT17) ? ~BIT17_MASK : 0)))
#define SIGN_EXT18(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT18) ? ~BIT18_MASK : 0)))
#define SIGN_EXT21(_val)                               ((int32_t)((_val) | (((_val) & MASK_SIGN_BIT21) ? ~BIT21_MASK : 0)))

// --------------------------------
// RISC-V specific definitions
//

// Disassembly macros. Note, the raw instruction value could be byte swapped to match the
// the listings of the GNU assembler, meaning the left most byte is the least significant
// (RISC-V is little endian by default---see [1] section 1.5). The objdump disassembly
// output does not do this and the word reads as per the manual. This model does the latter
// as it is easier to cross-reference to the instruction definitions.

#define RV32I_DISASSEM_B_TYPE(_instr,_str,_rs1,_rs2,_imm_b)  {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %s %d\n",  (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr?'\'':' ',              \
                                                            _str, rmap(_rs1), rmap(_rs2),  _imm_b);                                      \
}

#define RV32I_DISASSEM_R_TYPE(_instr,_str,_rd,_rs1,_rs2)     {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'':' ',            \
                                                            _str,rmap(_rd),rmap(_rs1), abi_en ? rmap_str[_rs2] : xmap_str[_rs2]);        \
}

#define RV32I_DISASSEM_RA_TYPE(_instr,_str,_rd,_rs1,_rs2)    {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s (%s)\n",  (uint32_t)state.hart[curr_hart].pc, _instr,                                 \
                                                             _str,rmap(_rd),rmap(_rs2), abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);       \
}

#define RV32I_DISASSEM_RF_TYPE(_instr,_str,_rd,_rs1,_rs2)    {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr,                                   \
                                                           _str,fmap(_rd),fmap(_rs1), abi_en ? fmap_str[_rs2] : fxmap_str[_rs2]);        \
}

#define RV32I_DISASSEM_RFCVT1_TYPE(_instr,_str,_rd,_rs1,_rs2) {                                                                          \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr,                                      \
                                                        _str,rmap(_rd), abi_en ? fmap_str[_rs1] : fxmap_str[_rs1]);                      \
}

#define RV32I_DISASSEM_RFCVT2_TYPE(_instr,_str,_rd,_rs1,_rs2) {                                                                          \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr, _str,fmap(_rd),                      \
                                                        abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);                                       \
}

#define RV32I_DISASSEM_RFCVT3_TYPE(_instr,_str,_rd,_rs1,_rs2) {                                                                          \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr, _str,fmap(_rd),                      \
                                                        abi_en ? fmap_str[_rs1] : fxmap_str[_rs1]);                                      \
}

#define RV32I_DISASSEM_R4_TYPE(_instr,_str,_rd,_rs1,_rs2,_rs3) {                                                                         \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s %s %s %s\n",  (uint32_t)state.hart[curr_hart].pc, _instr,                                \
                                                              _str,fmap(_rd),fmap(_rs1),fmap(_rs2),                                      \
                                                              abi_en ? fmap_str[_rs3] : fxmap_str[_rs3]);                                \
}

#define RV32I_DISASSEM_I_TYPE(_instr,_str,_rd,_rs1,_imm_i)   {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %s %d\n",  (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'' : ' ',          \
                                                            _str, rmap(_rd),  rmap(_rs1),  _imm_i);                                      \
}

#define RV32I_DISASSEM_S_TYPE(_instr,_str,_rs1,_rs2,_imm_s)  {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %d(%s)\n", (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'' : ' ',          \
                                                            _str, rmap(_rs2), _imm_s, abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);         \
}

#define RV32I_DISASSEM_SFS_TYPE(_instr,_str,_rs1,_rs2,_imm_s) {                                                                          \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %d(%s)\n", (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'' : ' ',          \
                                                            _str, fmap(_rs2), _imm_s, abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);         \
}

#define RV32I_DISASSEM_IL_TYPE(_instr,_str,_rd,_rs1,_imm_i)  {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %d(%s)\n", (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'' : ' ',          \
                                                            _str, rmap(_rd),  _imm_i, abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);         \
}

#define RV32I_DISASSEM_IF_TYPE(_instr,_str,_imm_i)           {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %d, %d\n",    (uint32_t)state.hart[curr_hart].pc, _instr,                                   \
                                                           _str, ((_imm_i)>>4)&0xf, ((_imm_i)>>0)&0xf);                                  \
}

#define RV32I_DISASSEM_IFS_TYPE(_instr,_str,_rd,_rs1,_imm_i) {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %d(%s)\n", (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'' : ' ',          \
                                                            _str, fmap(_rd), _imm_i, abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);          \
}

#define RV32I_DISASSEM_ICSR_TYPE(_instr,_str,_rd,_csr,_rs1)  {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s 0x%03x, %s\n", (uint32_t)state.hart[curr_hart].pc,_instr,                                \
                                                               _str,rmap(_rd),_csr&0xfff, abi_en ? rmap_str[_rs1] : xmap_str[_rs1]);     \
}
#define RV32I_DISASSEM_ICSRI_TYPE(_instr,_str,_rd,_csr,_imm) {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x    %s %s 0x%03x, %d\n", (uint32_t)state.hart[curr_hart].pc, _instr,                               \
                                                               _str, rmap(_rd),_csr & 0xfff, _imm);                                      \
}
#define RV32I_DISASSEM_J_TYPE(_instr,_str,_rd,_imm_j)        {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s %d\n",     (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr?'\'':' ',              \
                                                            _str, rmap(_rd),  _imm_j);                                                   \
}

#define RV32I_DISASSEM_U_TYPE(_instr,_str,_rd,_imm_u)        {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s %s 0x%08x\n", (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr ? '\'':' ',            \
                                                            _str, rmap(_rd),  _imm_u >> 12);                                             \
}

#define RV32I_DISASSEM_SYS_TYPE(_instr,_str)                 {                                                                           \
    if (disassemble || rt_disassem)                                                                                                      \
        fprintf(dasm_fp, "%08x: 0x%08x%c   %s\n",           (uint32_t)state.hart[curr_hart].pc, _instr, cmp_instr?'\'':' ',_str);        \
}
#define RV32I_DISASSEM_PC_JUMP                               {                                                                           \
    if (rt_disassem)                                                                                                                     \
        fprintf(dasm_fp, "    *\n");                                                                                                     \
}
#define RV32I_DISASSEM_INT_PC_JUMP                           {                                                                           \
    if (rt_disassem)                                                                                                                     \
        fprintf(dasm_fp, "   -*-\n");                                                                                                    \
}

// -------------------------------------------------------------------------
// TYPEDEFS
// -------------------------------------------------------------------------

// Define a type for time
typedef  int64_t rv32i_time_t;

// Define the type of the callback functions. These must be used
// by any function registered with the ISS.

// External interrupt callback is passed current time value. The function can
// optionally return a future time in 'wakeup_time' which will delay the
// subsequent recall to be at, or beyond, that time. Any time less will result
// in the function be called in the next time slot. The return value is a
// 32 bit bitmap of requesting external interrupts.

typedef uint32_t (*p_rv32i_intcallback_t) (const rv32i_time_t time, rv32i_time_t *wakeup_time);

// Memory access callback is passed a 32 bit address, a pointer to a 32 bit data
// word, a type, and the current time. The type is one of the 6 values defined
// above. If a write type, 'data' will point to the value to be written, else it
// should be updated with the read value to be returned, if the callback intercepts
// the address. If the callback matches against the provided address, the function
// must return a non-zero value. If the address did not match one processed by the
// function, then -1 must be returned. By default the ISS will assume a single
// cycle access for intercepted addresses (i.e. 0 wait states). If the value returned
// is greater than 0, the cycle count will be incremented by the value returned.

typedef int      (*p_rv32i_memcallback_t) (const uint32_t byte_addr, uint32_t &data, const int type, const rv32i_time_t time);

// Decode table entry structure type definition
typedef struct
{
    const char*                                        instr_name;     // Instruction name string for disassembly
    int                                                instr_fmt;      // Instruction format
} rv32i_table_entry_t;

// Forward reference the decode table structure type
struct rv32i_decode_table_t;

// Current decoded instruction type, combining opcode and a pointer to its
// entry in the decode table
typedef struct {
    uint32_t                                           instr;          // Full instruction opcode
    uint32_t                                           opcode;         // Opcode field
    uint32_t                                           funct3;         // Sub-function value (R, I, S and B types)
    uint32_t                                           funct7;         // Sub-function value (R-type)
    uint32_t                                           rd;             // Destination register
    uint32_t                                           rs1;            // Source register 1
    uint32_t                                           rs2;            // Source register 2
    uint32_t                                           imm_i;          // Sign extended immediate value for I type
    uint32_t                                           imm_s;          // Sign extended immediate value for S type
    uint32_t                                           imm_b;          // Sign extended immediate value for B type
    uint32_t                                           imm_u;          // Sign extended immediate value for U type
    uint32_t                                           imm_j;          // Sign extended immediate value for J type
    rv32i_table_entry_t                                entry;          // Copy of instruction tabel entry
} rv32i_decode_t, *p_rv32i_decode_t;

// Forward class reference for following type definition
class rv32i_cpu;

// Define a "pointer to a function" type to match rv32i_cpu instruction member functions
typedef void (rv32i_cpu::* pFunc_t) (const p_rv32i_decode_t);

typedef struct rv32i_decode_table_t
{
    // Flag to indicate 'ref' a sub-table reference (and not a reference to an instruction entry)
    bool                                               sub_table;

    // Either a reference to an instruction entry or a reference to a sub-table
    union {
        rv32i_table_entry_t                            entry;          // A decoded entry
        rv32i_decode_table_t*                          p_entry;        // A pointer to a sub-table
    } ref;

    // Pointer to an instruction function
    pFunc_t                                            p;
} rv32i_decode_table_t;

// Model configuration structure
struct  rv32i_cfg_s {
    const char*    exec_fname;
    bool           user_fname;
    unsigned       num_instr;
    bool           rt_dis;
    bool           dis_en;
    bool           abi_en;
    bool           hlt_on_inst_err;
    bool           hlt_on_ecall;
    bool           hlt_on_ebreak;
    bool           en_brk_on_addr;
    bool           dump_regs;
    bool           dump_csrs;
    bool           use_cycles_for_mtime;
    uint32_t       num_mem_dump_words;
    uint32_t       mem_dump_start;
    bool           gdb_mode;
    uint32_t       gdb_ip_portnum;
    uint32_t       brk_addr;
    bool           update_rst_vec;
    uint32_t       new_rst_vec;
    FILE*          dbg_fp;

    rv32i_cfg_s()
    {
        exec_fname           = "test.exe";
        user_fname           = false;
        num_instr            = 0;
        rt_dis               = false;
        dis_en               = false;
        abi_en               = false;
        hlt_on_inst_err      = false;
        hlt_on_ecall         = false;
        hlt_on_ebreak        = false;
        en_brk_on_addr       = false;
        use_cycles_for_mtime = false;
        dump_regs            = false;
        dump_csrs            = false;
        num_mem_dump_words   = 0;
        mem_dump_start       = 0x1000;
        gdb_mode             = false;
        gdb_ip_portnum       = RV32_DEFAULT_TCP_PORT;
        brk_addr             = RISCV_TEST_ENV_TERMINATE_ADDR;
        update_rst_vec       = false;
        new_rst_vec          = RV32I_RESET_VECTOR;
        dbg_fp               = stdout;
    }
};

#endif
