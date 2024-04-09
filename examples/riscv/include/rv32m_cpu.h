// =========================================================================
//
//  File Name:         rv32m_cpu.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//    Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the definitions for the rv32m_cpu derived class
//
//    This file is part of the M extended RISC-V instruction
//    set simulator (rv32m_cpu).
//
//  Revision History:
//    Date      Version    Description
//    07/2023   2023.??    Updates for supporting FreeRTOS
//    01/2023   2023.01    Released with OSVVM CoSim
//    24th July 2021       Earlier version
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

#ifndef _RV32M_CPU_H_
#define _RV32M_CPU_H_

#include "rv32_extensions.h"
#include "rv32i_cpu_hdr.h"
#include "rv32csr_cpu.h"
#include RV32M_INCLUDE

class rv32m_cpu : public RV32_M_INHERITANCE_CLASS
{
public:
             LIBRISCV32_API      rv32m_cpu      (FILE* dbgfp = stdout);
    virtual  LIBRISCV32_API      ~rv32m_cpu()   { };

private:
    // ------------------------------------------------
    // Private member variables
    // ------------------------------------------------

    const char mul_str     [DISASSEM_STR_SIZE] = "mul      ";
    const char mulh_str    [DISASSEM_STR_SIZE] = "mulh     ";
    const char mulhsu_str  [DISASSEM_STR_SIZE] = "mulhsu   ";
    const char mulhu_str   [DISASSEM_STR_SIZE] = "mulhu    ";
    const char div_str     [DISASSEM_STR_SIZE] = "div      ";
    const char divu_str    [DISASSEM_STR_SIZE] = "divu     ";
    const char rem_str     [DISASSEM_STR_SIZE] = "rem      ";
    const char remu_str    [DISASSEM_STR_SIZE] = "remu     ";

    // ------------------------------------------------
    // Private member functions
    // ------------------------------------------------

    // M extension instructions
    void mul                             (const p_rv32i_decode_t);
    void mulh                            (const p_rv32i_decode_t);
    void mulhsu                          (const p_rv32i_decode_t);
    void mulhu                           (const p_rv32i_decode_t);
    void div                             (const p_rv32i_decode_t);
    void divu                            (const p_rv32i_decode_t);
    void rem                             (const p_rv32i_decode_t);
    void remu                            (const p_rv32i_decode_t);

protected:


};

#endif
