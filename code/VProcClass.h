//=====================================================================
//
// VProcClass.h                                       Date: 2023/12/29
//
// Copyright (c) 2023-2024 Simon Southwell.
//
// This file is part of VProc.
//
// VProc is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VProc is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VProc. If not, see <http://www.gnu.org/licenses/>.
//
//=====================================================================
// C++ API class wrapper for VProc C API
//=====================================================================

extern "C"
{
#include "VUser.h"
}

class VProc
{
public:
         // Constructor
         VProc        (const unsigned   nodeIn) : node(nodeIn) {};

    // API methods
    int  write        (const unsigned   addr,   const unsigned    data, const int      delta)  {return VWrite        (addr,  data, delta,  node);};
    int  read         (const unsigned   addr,         unsigned   *data, const int      delta)  {return VRead         (addr,  data, delta,  node);};
    int  burstWrite   (const unsigned   addr,         void       *data, const unsigned length) {return VBurstWrite   (addr,  data, length, node);};
    int  burstRead    (const unsigned   addr,         void       *data, const unsigned length) {return VBurstRead    (addr,  data, length, node);};
    int  tick         (const unsigned   ticks)                                                 {return VTick         (ticks,               node);};
    void regInterrupt (const int        level,  const pVUserInt_t func)                        {       VRegInterrupt (level, func,         node);};
    void regUser      (const pVUserCB_t func)                                                  {       VRegUser      (func,                node);};

private:

    // VProc node number this object is accessing
    unsigned node;
};