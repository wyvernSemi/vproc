// =========================================================================
//
//  File Name:         rv32csr_cpu_hdr.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//     Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the definitions for the rv32csr_cpu derived class
//
//    This file is part of the Zicsr extended RISC-V instruction
//    set simulator (rv32csr_cpu).
//
//  Revision History:
//    Date      Version    Description
//    07/2023   2023.??    Updates for supporting FreeRTOS
//    01/2023   2023.01    Released with OSVVM CoSim
//    Date: 12th July 2021 Earlier version
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

#ifndef _RV32CSR_CPU_HDR_H_
#define _RV32CSR_CPU_HDR_H_

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include <cstdio>
#include <cstdint>

#include "rv32i_cpu.h"

#define RV32CSR_PRIMARY_TBL_SYS_OFFSET                 28

#define RV32CSR_MXLEN32                                0x40000000
                                                       
#define RV32CSR_EXT_A                                  0x00000001
#define RV32CSR_EXT_B                                  0x00000002
#define RV32CSR_EXT_C                                  0x00000004
#define RV32CSR_EXT_D                                  0x00000008
#define RV32CSR_EXT_E                                  0x00000010
#define RV32CSR_EXT_F                                  0x00000020
#define RV32CSR_EXT_G                                  0x00000040
#define RV32CSR_EXT_H                                  0x00000080
#define RV32CSR_EXT_I                                  0x00000100
#define RV32CSR_EXT_J                                  0x00000200
#define RV32CSR_EXT_K                                  0x00000400
#define RV32CSR_EXT_L                                  0x00000800
#define RV32CSR_EXT_M                                  0x00001000
#define RV32CSR_EXT_N                                  0x00002000
#define RV32CSR_EXT_O                                  0x00004000
#define RV32CSR_EXT_P                                  0x00008000
#define RV32CSR_EXT_Q                                  0x00010000
#define RV32CSR_EXT_R                                  0x00020000
#define RV32CSR_EXT_S                                  0x00040000
#define RV32CSR_EXT_T                                  0x00080000
#define RV32CSR_EXT_U                                  0x00100000
#define RV32CSR_EXT_V                                  0x00200000
#define RV32CSR_EXT_W                                  0x00400000
#define RV32CSR_EXT_X                                  0x00800000
#define RV32CSR_EXT_Y                                  0x01000000
#define RV32CSR_EXT_Z                                  0x02000000

// CSR address bit fields
#define RV32CSR_ADDR_PRIV_MASK                         0x300
#define RV32CSR_USER_PRIV                              0x000
#define RV32CSR_SUPERVISOR_PRIV                        0x100
#define RV32CSR_HYPERVISOR_PRIV                        0x200
#define RV32CSR_MACHINE_PRIV                           0x300

// CSR register addresses

// Floating point CSR addresses
#define RV32CSR_ADDR_FFLAGS                            0x001
#define RV32CSR_ADDR_FRM                               0x002
#define RV32CSR_ADDR_FCSR                              0x003

// Machine information
#define RV32CSR_ADDR_MVENDORID                         0xf11
#define RV32CSR_ADDR_MARCHID                           0xf12
#define RV32CSR_ADDR_MIMPID                            0xf13
#define RV32CSR_ADDR_MHARTID                           0xf14

// Machine Trap Setup
#define RV32CSR_ADDR_MSTATUS                           0x300
#define RV32CSR_ADDR_MISA                              0x301
#define RV32CSR_ADDR_MEDELEG                           0x302
#define RV32CSR_ADDR_MIDELEG                           0x303
#define RV32CSR_ADDR_MIE                               0x304
#define RV32CSR_ADDR_MTVEC                             0x305
#define RV32CSR_ADDR_MCOUNTEREN                        0x306

// Machine Trap Handling
#define RV32CSR_ADDR_MSCRATCH                          0x340
#define RV32CSR_ADDR_MEPC                              0x341
#define RV32CSR_ADDR_MCAUSE                            0x342
#define RV32CSR_ADDR_MTVAL                             0x343
#define RV32CSR_ADDR_MIP                               0x344

// Machine Memory protection
#define RV32CSR_ADDR_PMPCFG0                           0x3A0
#define RV32CSR_ADDR_PMPCFG1                           0x3A1
#define RV32CSR_ADDR_PMPCFG2                           0x3A2
#define RV32CSR_ADDR_PMPCFG3                           0x3A3
#define RV32CSR_ADDR_PMPADDR0                          0x3B0
#define RV32CSR_ADDR_PMPADDR1                          0x3B1
#define RV32CSR_ADDR_PMPADDR2                          0x3B2
#define RV32CSR_ADDR_PMPADDR3                          0x3B3
#define RV32CSR_ADDR_PMPADDR4                          0x3B4
#define RV32CSR_ADDR_PMPADDR5                          0x3B5
#define RV32CSR_ADDR_PMPADDR6                          0x3B6
#define RV32CSR_ADDR_PMPADDR7                          0x3B7
#define RV32CSR_ADDR_PMPADDR8                          0x3B8
#define RV32CSR_ADDR_PMPADDR9                          0x3B9
#define RV32CSR_ADDR_PMPADDR10                         0x3BA
#define RV32CSR_ADDR_PMPADDR11                         0x3BB
#define RV32CSR_ADDR_PMPADDR12                         0x3BC
#define RV32CSR_ADDR_PMPADDR13                         0x3BD
#define RV32CSR_ADDR_PMPADDR14                         0x3BE
#define RV32CSR_ADDR_PMPADDR15                         0x3BF

// Machine Counter/Timers
#define RV32CSR_ADDR_MCYCLE                            0xB00
#define RV32CSR_ADDR_MINSTRET                          0xB02
#define RV32CSR_ADDR_MHPMCOUNTER3                      0xB03
#define RV32CSR_ADDR_MHPMCOUNTER4                      0xB04
#define RV32CSR_ADDR_MHPMCOUNTER5                      0xB05
#define RV32CSR_ADDR_MHPMCOUNTER6                      0xB06
#define RV32CSR_ADDR_MHPMCOUNTER7                      0xB07
#define RV32CSR_ADDR_MHPMCOUNTER8                      0xB08
#define RV32CSR_ADDR_MHPMCOUNTER9                      0xB09
#define RV32CSR_ADDR_MHPMCOUNTER10                     0xB0A
#define RV32CSR_ADDR_MHPMCOUNTER11                     0xB0B
#define RV32CSR_ADDR_MHPMCOUNTER12                     0xB0C
#define RV32CSR_ADDR_MHPMCOUNTER13                     0xB0D
#define RV32CSR_ADDR_MHPMCOUNTER14                     0xB0E
#define RV32CSR_ADDR_MHPMCOUNTER15                     0xB0F
#define RV32CSR_ADDR_MHPMCOUNTER16                     0xB10
#define RV32CSR_ADDR_MHPMCOUNTER17                     0xB11
#define RV32CSR_ADDR_MHPMCOUNTER18                     0xB12
#define RV32CSR_ADDR_MHPMCOUNTER19                     0xB13
#define RV32CSR_ADDR_MHPMCOUNTER20                     0xB14
#define RV32CSR_ADDR_MHPMCOUNTER21                     0xB15
#define RV32CSR_ADDR_MHPMCOUNTER22                     0xB16
#define RV32CSR_ADDR_MHPMCOUNTER23                     0xB17
#define RV32CSR_ADDR_MHPMCOUNTER24                     0xB18
#define RV32CSR_ADDR_MHPMCOUNTER25                     0xB19
#define RV32CSR_ADDR_MHPMCOUNTER26                     0xB1A
#define RV32CSR_ADDR_MHPMCOUNTER27                     0xB1B
#define RV32CSR_ADDR_MHPMCOUNTER28                     0xB1C
#define RV32CSR_ADDR_MHPMCOUNTER29                     0xB1D
#define RV32CSR_ADDR_MHPMCOUNTER30                     0xB1E
#define RV32CSR_ADDR_MHPMCOUNTER31                     0xB1F
#define RV32CSR_ADDR_MCYCLEH                           0xB80
#define RV32CSR_ADDR_MINSTRETH                         0xB82
#define RV32CSR_ADDR_MHPMCOUNTER3H                     0xB83
#define RV32CSR_ADDR_MHPMCOUNTER4H                     0xB84
#define RV32CSR_ADDR_MHPMCOUNTER5H                     0xB85
#define RV32CSR_ADDR_MHPMCOUNTER6H                     0xB86
#define RV32CSR_ADDR_MHPMCOUNTER7H                     0xB87
#define RV32CSR_ADDR_MHPMCOUNTER8H                     0xB88
#define RV32CSR_ADDR_MHPMCOUNTER9H                     0xB89
#define RV32CSR_ADDR_MHPMCOUNTER10H                    0xB8A
#define RV32CSR_ADDR_MHPMCOUNTER11H                    0xB8B
#define RV32CSR_ADDR_MHPMCOUNTER12H                    0xB8C
#define RV32CSR_ADDR_MHPMCOUNTER13H                    0xB8D
#define RV32CSR_ADDR_MHPMCOUNTER14H                    0xB8E
#define RV32CSR_ADDR_MHPMCOUNTER15H                    0xB8F
#define RV32CSR_ADDR_MHPMCOUNTER16H                    0xB90
#define RV32CSR_ADDR_MHPMCOUNTER17H                    0xB91
#define RV32CSR_ADDR_MHPMCOUNTER18H                    0xB92
#define RV32CSR_ADDR_MHPMCOUNTER19H                    0xB93
#define RV32CSR_ADDR_MHPMCOUNTER20H                    0xB94
#define RV32CSR_ADDR_MHPMCOUNTER21H                    0xB95
#define RV32CSR_ADDR_MHPMCOUNTER22H                    0xB96
#define RV32CSR_ADDR_MHPMCOUNTER23H                    0xB97
#define RV32CSR_ADDR_MHPMCOUNTER24H                    0xB98
#define RV32CSR_ADDR_MHPMCOUNTER25H                    0xB99
#define RV32CSR_ADDR_MHPMCOUNTER26H                    0xB9A
#define RV32CSR_ADDR_MHPMCOUNTER27H                    0xB9B
#define RV32CSR_ADDR_MHPMCOUNTER28H                    0xB9C
#define RV32CSR_ADDR_MHPMCOUNTER29H                    0xB9D
#define RV32CSR_ADDR_MHPMCOUNTER30H                    0xB9E
#define RV32CSR_ADDR_MHPMCOUNTER31H                    0xB9F

// Machine counter setup
#define RV32CSR_ADDR_MCOUNTINHIBIT                     0x320
#define RV32CSR_ADDR_MHPMEVENT3                        0x323
#define RV32CSR_ADDR_MHPMEVENT4                        0x324
#define RV32CSR_ADDR_MHPMEVENT5                        0x325
#define RV32CSR_ADDR_MHPMEVENT6                        0x326
#define RV32CSR_ADDR_MHPMEVENT7                        0x327
#define RV32CSR_ADDR_MHPMEVENT8                        0x328
#define RV32CSR_ADDR_MHPMEVENT9                        0x329
#define RV32CSR_ADDR_MHPMEVENT10                       0x32A
#define RV32CSR_ADDR_MHPMEVENT11                       0x32B
#define RV32CSR_ADDR_MHPMEVENT12                       0x32C
#define RV32CSR_ADDR_MHPMEVENT13                       0x32D
#define RV32CSR_ADDR_MHPMEVENT14                       0x32E
#define RV32CSR_ADDR_MHPMEVENT15                       0x32F
#define RV32CSR_ADDR_MHPMEVENT16                       0x330
#define RV32CSR_ADDR_MHPMEVENT17                       0x331
#define RV32CSR_ADDR_MHPMEVENT18                       0x332
#define RV32CSR_ADDR_MHPMEVENT19                       0x333
#define RV32CSR_ADDR_MHPMEVENT20                       0x334
#define RV32CSR_ADDR_MHPMEVENT21                       0x335
#define RV32CSR_ADDR_MHPMEVENT22                       0x336
#define RV32CSR_ADDR_MHPMEVENT23                       0x337
#define RV32CSR_ADDR_MHPMEVENT24                       0x338
#define RV32CSR_ADDR_MHPMEVENT25                       0x339
#define RV32CSR_ADDR_MHPMEVENT26                       0x33A
#define RV32CSR_ADDR_MHPMEVENT27                       0x33B
#define RV32CSR_ADDR_MHPMEVENT28                       0x33C
#define RV32CSR_ADDR_MHPMEVENT29                       0x33D
#define RV32CSR_ADDR_MHPMEVENT30                       0x33E
#define RV32CSR_ADDR_MHPMEVENT31                       0x33F

// Debug/Trace registers
#define RV32CSR_ADDR_TSELECT                           0x7A0
#define RV32CSR_ADDR_TDATA1                            0x7A1
#define RV32CSR_ADDR_TDATA2                            0x7A2
#define RV32CSR_ADDR_TDATA3                            0x7A3

#define RV32CSR_ADDR_DCSR                              0x7B0
#define RV32CSR_ADDR_DPC                               0x7B1
#define RV32CSR_ADDR_DSCRATCH0                         0x7B2
#define RV32CSR_ADDR_DSCRATCH1                         0x7B3

// CSR write masks (from perspective of CSR instructions)
#define RV32CSR_MISA_WR_MASK                           0x00000000 /* can't update in this implementation */
#define RV32CSR_MSTATUS_WR_MASK                        0x00000088
#define RV32CSR_MIP_WR_MASK                            0x00000000
#define RV32CSR_MIE_WR_MASK                            0x00000888
#define RV32CSR_MTVEC_WR_MASK                          0xffffffff
#define RV32CSR_MCYCLE_WR_MASK                         0xffffffff
#define RV32CSR_MINSTRET_WR_MASK                       0x00000000
#define RV32CSR_MHPMCOUNTERX_WR_MASK                   0x00000000 /* Reg implemented, counter not. */
#define RV32CSR_MHPMEVENTX_WR_MASK                     0x00000000 /* Reg implemented, hardwired 0 */
#define RV32CSR_MCOUNTEREN_WR_MASK                     0x00000000
#define RV32CSR_MCOUNTINHIBIT_WR_MASK                  0x00000001
#define RV32CSR_MSCRATCH_WR_MASK                       0xffffffff
#define RV32CSR_MEPC_WR_MASK                           0xfffffffe
#define RV32CSR_MCAUSE_WR_MASK                         0xffffffff
#define RV32CSR_MTVAL_WR_MASK                          0xffffffff
#define RV32CSR_FFLAGS_WR_MASK                         0x0000001f
#define RV32CSR_FRM_WR_MASK                            0x00000007
#define RV32CSR_FCSR_WR_MASK                           0x000000ff

#define RV32CSR_MSTATUS_FS_MASK                        0x00006000
#define RV32CSR_MSTATUS_FS_OFF                         0x00000000
#define RV32CSR_MSTATUS_FS_INITIAL                     0x00002000
#define RV32CSR_MSTATUS_FS_CLEAN                       0x00004000
#define RV32CSR_MSTATUS_FS_DIRTY                       0x00006000

// CSR memory protection registers are implemented but currently hardwired to 0
#define RV32CSR_PMPX_WR_MASK                           0x00000000

// CSR operation decode on fmt fields
#define RV32CSR_OP_RW(_op)                             ((_op & 0x3) == 0x1)
#define RV32CSR_OP_RS(_op)                             ((_op & 0x3) == 0x2)
#define RV32CSR_OP_RC(_op)                             ((_op & 0x3) == 0x3)
#define RV32CSR_IMM(_op)                               (_op  & 0x4)

// MIP bit masks
#define RV32CSR_MEIP_BITMASK                           0x800
#define RV32CSR_MTIP_BITMASK                           0x080
#define RV32CSR_MSIP_BITMASK                           0x008

// MIE bit masks
#define RV32CSR_MEIE_BITMASK                           0x800
#define RV32CSR_MTIE_BITMASK                           0x080
#define RV32CSR_MSIE_BITMASK                           0x008

// MSTATUS bit masks
#define RV32CSR_MIE_BITMASK                            0x00000008
#define RV32CSR_MPIE_BITMASK                           0x00000080
#define RV32CSR_MPP_BITMASK                            0x00001800
#define RV32CSR_MPRV_BITMASK                           0x00010000

#define RV32CSR_MTVEC_MODE_MASK                        0x00000003
#define RV32CSR_MTVEC_MODE_DIRECT                      0x00000000
#define RV32CSR_MTVEC_MODE_VECTORED                    0x00000001

// Interrupt causes
#define RV32CSR_MCAUSE_INT_MASK                        0x80000000
#define RV32CSR_INT_MSW_CAUSE                          (0x00000003 | RV32CSR_MCAUSE_INT_MASK)
#define RV32CSR_INT_MTIM_CAUSE                         (0x00000007 | RV32CSR_MCAUSE_INT_MASK)
#define RV32CSR_INT_MEXT_CAUSE                         (0x0000000B | RV32CSR_MCAUSE_INT_MASK)

#endif