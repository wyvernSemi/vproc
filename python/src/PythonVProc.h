//=====================================================================
//
// PythonVProc.h                                     Date: 2024/01/25
//
// Copyright (c) 2024 Simon Southwell.
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

#include <stdint.h>
#include <Python.h>
#include <dlfcn.h>
#include "VProc.h"

#ifndef _PYTHONVPROC_H_
#define _PYTHONVPROC_H_

#define DEFAULTSTRBUFSIZE      256

// Pointer types for external API functions. Must match prototypes in VUser.h
typedef int      (*wfunc_p)      (const unsigned, const unsigned, const int, const unsigned);
typedef int      (*wbefunc_p)    (const unsigned, const unsigned, const unsigned, const int, const unsigned);
typedef int      (*rfunc_p)      (const unsigned, unsigned *, const int, const unsigned);
typedef int      (*wbfunc_p)     (const unsigned, void *, const unsigned, const unsigned);
typedef int      (*wbbefunc_p)   (const unsigned, void *, const unsigned, const unsigned, const unsigned, const unsigned);
typedef int      (*rbfunc_p)     (const unsigned, void *, const unsigned, const unsigned);
typedef int      (*tkfunc_p)     (const unsigned, const unsigned );
typedef void     (*regirqfunc_p) (const pPyIrqCB_t, const unsigned);
typedef int      (*pyirqcb_p)    (const int, const int);
typedef uint32_t (*pyfetchirq_p) (void *, const uint32_t);

// API functions called from python 
int      RunPython      (const int      node);
uint32_t PyWrite        (const uint32_t addr,  const uint32_t data,  const int delta, const uint32_t node);
uint32_t PyWriteBE      (const uint32_t addr,  const uint32_t data,  const uint32_t be, const int delta, const uint32_t node);
uint32_t PyRead         (const uint32_t addr,  const int      delta, const uint32_t node);
uint32_t PyTick         (const uint32_t ticks, const uint32_t node);
uint32_t PyBurstWrite   (const uint32_t addr,  void *data, const uint32_t len, const uint32_t node);
uint32_t PyBurstWriteBE (const uint32_t addr,  void *data, const uint32_t len, const uint32_t fbe, const uint32_t lbe, const uint32_t node);
uint32_t PyBurstRead    (const uint32_t addr,  void *data, const uint32_t len, const uint32_t node);

uint32_t PyRegIrq       (const pPyIrqCB_t func, const uint32_t node);
uint32_t PyFetchIrq     (void *irq, const uint32_t node);

#endif
