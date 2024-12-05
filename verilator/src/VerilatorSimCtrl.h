// ====================================================================
// VerilatorSimCtrl.h                                  Date: 2024/12/03
//
// Copyright (c) 2024 Simon Southwell
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
// ===================================================================

#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <thread>
#include <iostream>
#include <iomanip>
#include <iterator>
#include <vector>
#include <string>
#include <cmath>
#include <regex>

#include "VProcClass.h"

#ifndef _VERILATORSIMCTRL_H_
#define _VERILATORSIMCTRL_H_

#define VSC_CYC_COUNT_ADDR   0
#define VSC_CLK_PERIOD_ADDR  1
#define VSC_FINISH_ADDR      2

#define VSC_TIME_PS          0
#define VSC_TIME_NS          1
#define VSC_TIME_US          2
#define VSC_TIME_MS          3
#define VSC_TIME_S           4
#define VSC_TIME_CYCLES      5

#define VSC_NO_ERROR         0
#define VSC_FINISHING        1
#define VSC_SYNTAX_ERR       2

#define COUNT2NSF(_c, _p) ((double)(((uint64_t)(_c)+1)*(uint64_t)(_p))/1000.0)
#define COUNT2USF(_c, _p) ((double)(((uint64_t)(_c)+1)*(uint64_t)(_p))/1000000.0)
#define COUNT2MSF(_c, _p) ((double)(((uint64_t)(_c)+1)*(uint64_t)(_p))/1000000.0)
#define COUNT2SF(_c, _p)  ((double)(((uint64_t)(_c)+1)*(uint64_t)(_p))/1000000.0)

#define TIME2PS(_t,_u) ((_t) * (((_u) == VSC_TIME_PS) ? 1.0 :                  \
                                ((_u) == VSC_TIME_NS) ? 1000.0 :               \
                                ((_u) == VSC_TIME_US) ? 1000000.0 :            \
                                ((_u) == VSC_TIME_MS) ? 1000000000.0 :         \
                                                        1000000000000.0))

extern void flushfst (void);
extern void VerilatorSimCtrl(void);

#endif