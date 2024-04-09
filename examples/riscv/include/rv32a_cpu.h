// =========================================================================
//
//  File Name:         rv32a_cpu.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//    Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the definitions for the rv32csr_cpu derived class
//
//    This file is part of the A extended RISC-V instruction
//    set simulator (rv32a_cpu).
//
//  Revision History:
//    Date      Version    Description
//    07/2023   2023.??    Updates for supporting FreeRTOS
//    01/2023   2023.01    Released with OSVVM CoSim
//    26th July 2021       Earlier version
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

#ifndef _RV32A_CPU_H_
#define _RV32A_CPU_H_

#include "rv32_extensions.h"
#include "rv32i_cpu_hdr.h"
#include "rv32csr_cpu.h"
#include RV32A_INCLUDE

class rv32a_cpu : public RV32_A_INHERITANCE_CLASS
{
public:
             LIBRISCV32_API      rv32a_cpu      (FILE* dbgfp = stdout);
    virtual  LIBRISCV32_API      ~rv32a_cpu()   { };

protected:
    // Add an AMO instruction secondary table here. Make public to allow
    // RV64A instructions to be added in a future derived class.
    rv32i_decode_table_t  amo_tbl        [RV32I_NUM_SECONDARY_OPCODES];

private:
    // ------------------------------------------------
    // Internal Type definitions
    // ------------------------------------------------

    // Structure for LR.W reserved memory area
    struct rsvd_mem_s
    {
        bool active;
        uint32_t start_addr;
        uint32_t end_addr;

        rsvd_mem_s()
        {
            active     = false;
            start_addr = 0;
            end_addr   = 0;
        }
    };

    // ------------------------------------------------
    // Private member variables
    // ------------------------------------------------

    // Granularity of LR.W reserved areas
    static const uint32_t rsvd_mem_block_bytes        = 32;

    const char lrw_str     [DISASSEM_STR_SIZE] = "lr.w     ";
    const char scw_str     [DISASSEM_STR_SIZE] = "sc.w     ";
    const char amoswap_str [DISASSEM_STR_SIZE] = "amoswap.w";
    const char amoadd_str  [DISASSEM_STR_SIZE] = "amoadd.w ";
    const char amoxor_str  [DISASSEM_STR_SIZE] = "amoxor.w ";
    const char amoand_str  [DISASSEM_STR_SIZE] = "amoand.w ";
    const char amoor_str   [DISASSEM_STR_SIZE] = "amoor.w  ";
    const char amomin_str  [DISASSEM_STR_SIZE] = "amomin.w ";
    const char amomax_str  [DISASSEM_STR_SIZE] = "amomax.w ";
    const char amominu_str [DISASSEM_STR_SIZE] = "amominu.w";
    const char amomaxu_str [DISASSEM_STR_SIZE] = "amomaxu.w";

    // Tertiary table for AMO.W instructions
    rv32i_decode_table_t  amow_tbl       [RV32I_NUM_TERTIARY_OPCODES];

    // Reserved memory state
    rsvd_mem_s rsvd_mem;

    // ------------------------------------------------
    // Private member functions
    // ------------------------------------------------

    // RV32A extension instruction methods
    void lrw                             (const p_rv32i_decode_t);
    void scw                             (const p_rv32i_decode_t);
    void amoswapw                        (const p_rv32i_decode_t);
    void amoaddw                         (const p_rv32i_decode_t);
    void amoxorw                         (const p_rv32i_decode_t);
    void amoandw                         (const p_rv32i_decode_t);
    void amoorw                          (const p_rv32i_decode_t);
    void amominw                         (const p_rv32i_decode_t);
    void amomaxw                         (const p_rv32i_decode_t); 
    void amominuw                        (const p_rv32i_decode_t);
    void amomaxuw                        (const p_rv32i_decode_t);
};

#endif
