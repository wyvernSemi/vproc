// =========================================================================
//
//  File Name:         rv32.h
//  Design Unit Name:
//  Revision:          OSVVM MODELS STANDARD VERSION
//
//  Maintainer:        Simon Southwell email:  simon.southwell@gmail.com
//  Contributor(s):
//    Simon Southwell      simon.southwell@gmail.com
//
//  Description:
//    Contains the class definition for the top level derived class
//
//    This file is part of the Zicsr extended RISC-V instruction
//    set simulator (rv32).
//
//  Revision History:
//    Date      Version    Description
//    07/2023   2023.??    Updates for supporting FreeRTOS
//    01/2023   2023.01    Released with OSVVM CoSim
//    12th July 2021       Earlier version
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

#ifndef _RV32_H_
#define _RV32_H_

#include "rv32_extensions.h"
#include RV32_TARGET_INCLUDE

// This class is the top level ISS implementation class, configurable
// to have only those extensions required to be modelled. The
// rv32_inheritance.h file defines which extensions are to be included.
class rv32 : public RV32_TARGET_INHERITANCE_CLASS
{
public:

    static const int major_ver = 0;
    static const int minor_ver = 28;

    LIBRISCV32_API rv32(FILE* dbg_fp = stdout) : RV32_TARGET_INHERITANCE_CLASS(dbg_fp)
    {
    };

    /*****************************************************/
    /* Add customisations and additional extensions here */
    /*****************************************************/
};

#endif
