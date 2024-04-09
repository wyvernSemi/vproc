// =========================================================================
//
//  File Name:         rv32c_cpu.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//    Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the definitions for the rv32c_cpu derived class
//
//    This file is part of the base RISC-V instruction set simulator
//
//  Revision History:
//    Date      Version    Description
//    01/2023   2023.01    Released with OSVVM CoSim
//    6th September 2021   Earlier version
//
//
//  This file is part of OSVVM.
//
//  Copyright (c) 2021 Simon Southwell. All rights reserved.
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

#ifndef _RV32C_CPU_H_
#define _RV32C_CPU_H_

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------
#include "rv32_extensions.h"
#include RV32C_INCLUDE

// -------------------------------------------------------------------------
// DEFINES
// -------------------------------------------------------------------------

// -------------------------------------------------------------------------
// Class definition for RISC-V RV32I instruction set simulator model
// -------------------------------------------------------------------------

class rv32c_cpu :  public RV32_C_INHERITANCE_CLASS
{
public:

    // ------------------------------------------------
    // Constructors/destructors
    // ------------------------------------------------

    // Constructor, with default configuration values
    LIBRISCV32_API             rv32c_cpu(FILE* dbgfp = stdout) : RV32_C_INHERITANCE_CLASS(dbgfp)
    {
        RV32_IADDR_ALIGN_MASK = 0x00000001;
    };

    // Virtual destructor for polymorphic class
    virtual LIBRISCV32_API     ~rv32c_cpu                    (){/* No dynamic allocation yet */}

    // ------------------------------------------------
    // Public methods (user interface)
    // ------------------------------------------------

    // ------------------------------------------------
    // Public member variables
    // ------------------------------------------------
public:

    // ------------------------------------------------
    // Protected member variables
    // ------------------------------------------------
protected:

    // ------------------------------------------------
    // Internal constant definitions
    // ------------------------------------------------

    // ------------------------------------------------
    // Internal Type definitions
    // ------------------------------------------------

    // ------------------------------------------------
    // Private member variables
    // ------------------------------------------------
 private:

     const uint32_t rv32c_illegal_instr = 0x0000;

     const uint32_t addi_opcode         = 0x13; // Also for slli, srli, srai
     const uint32_t fld_opcode          = 0x07;
     const uint32_t flw_opcode          = 0x07;
     const uint32_t fsd_opcode          = 0x27;
     const uint32_t fsw_opcode          = 0x27;
     const uint32_t lw_opcode           = 0x03;
     const uint32_t sw_opcode           = 0x23;
     const uint32_t j_opcode            = 0x6f;
     const uint32_t lui_opcode          = 0x37;
     const uint32_t add_opcode          = 0x33; // Also for sub, xor, or, and, mv
     const uint32_t branch_opcode       = 0x63;
     const uint32_t ebreak_opcode       = 0x73;
     const uint32_t jalr_opcode         = 0x67;

     const uint32_t fwidth_sgl          = 0x2;
     const uint32_t fwidth_dbl          = 0x3;
                                        
     const uint32_t width_word          = 0x2;

     const uint32_t ra_reg              = 1;
     const uint32_t sp_reg              = 2;

    // ------------------------------------------------
    // Virtual methods
    // ------------------------------------------------

    // ------------------------------------------------
    // Protected methods
    // ------------------------------------------------
protected:
    void increment_pc() { state.hart[curr_hart].pc = state.hart[curr_hart].pc + (cmp_instr ? 2 : 4); };

    // ------------------------------------------------
    // Private methods
    // ------------------------------------------------
private:

    // Compressed inctruction decode and conversion method
    uint32_t compressed_decode(const opcode_t instr);

    // Overloaded method to process 16 bit instructions
    uint32_t fetch_instruction();
};

#endif
