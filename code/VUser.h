//=====================================================================
//
// VUser.h                                            Date: 2005/01/10
//
// Copyright (c) 2005-2025 Simon Southwell.
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

#ifndef _VUSER_H_
#define _VUSER_H_

#include "VProc.h"
#include "VSched_pli.h"

#define DELTA_CYCLE     -1
#define GO_TO_SLEEP     0x7fffffff

#define MAX_INT_LEVEL   7
#define MIN_INT_LEVEL   1

#define MAXBURSTLEN     4096

// When compiling in windows (32- or 64-bit) ...
#ifdef WIN32
# include <windows.h>

// Map Linux dynamic loading calls to Windows equivalents
# define dlsym GetProcAddress
# define dlopen(_dll, _args) {LoadLibrary(_dll)}
# define dlerror() ""
# define dlclose FreeLibrary

// Define a type to cast node in print statements to avoid warnings
# ifdef _WIN64
typedef long long nodecast_t;
# else
typedef long      nodecast_t;
# endif
#else
typedef long      nodecast_t;
#endif

// Needed for Icarus and Verilator
# ifndef RTLD_DEFAULT
# define RTLD_DEFAULT ((void *) 0)
# endif

// Pointer to pthread_create compatible function
typedef void *(*pThreadFunc_t)(void *);

// VUser function prototypes for API

extern int  VWrite          (const uint32_t      addr,  const uint32_t  data, const int      delta,   const unsigned node);
extern int  VWriteBE        (const uint32_t      addr,  const uint32_t  data, const uint32_t be,      const int      delta, const uint32_t node);
extern int  VRead           (const uint32_t      addr,        uint32_t *data, const int      delta,   const uint32_t node);
extern int  VBurstWrite     (const uint32_t      addr,  void           *data, const uint32_t wordlen, const uint32_t node);
extern int  VBurstWriteBE   (const uint32_t      addr,  void           *data, const uint32_t wordlen, const uint32_t fbe,   const uint32_t lbe, const uint32_t node);
extern int  VBurstRead      (const uint32_t      addr,  void           *data, const uint32_t wordlen, const uint32_t node);

extern int  VWrite64        (const uint64_t      addr,  const uint64_t  data, const int      delta,   const unsigned node);
extern int  VWriteBE64      (const uint64_t      addr,  const uint64_t  data, uint32_t       be,      const int      delta, const uint32_t node);
extern int  VRead64         (const uint64_t      addr,        uint64_t *data, const int      delta,   const uint32_t node);
extern int  VBurstWrite64   (const uint64_t      addr,  void           *data, const uint32_t wordlen, const uint32_t node);
extern int  VBurstWriteBE64 (const uint64_t      addr,  void           *data, const uint32_t wordlen, const uint32_t fbe,   const uint32_t lbe, const uint32_t node);
extern int  VBurstRead64    (const uint64_t      addr,  void           *data, const uint32_t wordlen, const uint32_t node);

extern int  VTick           (const uint32_t      ticks, const uint32_t  node);
extern void VRegUser        (const pVUserCB_t    func,  const uint32_t  node);
extern void VRegIrq         (const pVUserIrqCB_t func,  const uint32_t  node);

// Internal function for Python interface
extern void VRegIrqPy       (const pPyIrqCB_t    func,  const uint32_t node);

// VUser function prototype for VInit in VSched.c
extern int  VUser           (const uint32_t      node);

#if defined(VPROC_VHDL) || defined (ICARUS) || defined (VPROC_SV)
# define VPrint(...) printf (__VA_ARGS__)
#else
# define VPrint(...) vpi_printf (__VA_ARGS__)
#endif

#ifdef DEBUG
#define DebugVPrint VPrint
#else
#define DebugVPrint //
#endif

// Pointer to VUserMain function type definition
typedef void (*pVUserMain_t)(void);

#endif
