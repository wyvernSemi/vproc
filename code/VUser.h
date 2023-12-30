//=====================================================================
//
// VUser.h                                            Date: 2005/01/10 
//
// Copyright (c) 2005-2024 Simon Southwell.
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

// Backards compatinility definitions
#define uint64 uint64_t

// Pointer to pthread_create compatible function
typedef void *(*pThreadFunc_t)(void *);

// VUser function prototypes for API

extern int  VWrite        (const unsigned   addr,  const unsigned     data, const int      delta, const unsigned node);
extern int  VRead         (const unsigned   addr,  unsigned          *data, const int      delta, const unsigned node);
extern int  VBurstWrite   (const unsigned   addr,  void              *data, const unsigned len,   const unsigned node);
extern int  VBurstRead    (const unsigned   addr,  void              *data, const unsigned len,   const unsigned node);
extern int  VTick         (const unsigned   ticks, const unsigned     node);
extern void VRegInterrupt (const int        level, const pVUserInt_t  func, const unsigned int node);
extern void VRegUser      (const pVUserCB_t func,  const unsigned int node);

// VUser function prototype for VInit in VSched.c
extern int  VUser         (const unsigned   node);

#ifdef VPROC_VHDL

// In windows using the FLI, a \n in the printf format string causes 
// two lines to be advanced, so replace new lines with carriage returns
// which seems to work
# ifdef _WIN32
# define VPrint(format, ...) {int len;                                             \
                              char formbuf[256];                                   \
                              strncpy(formbuf, format, 255);                       \
                              len = strlen(formbuf);                               \
                              for(int i = 0; i < len; i++)                         \
                                if (formbuf[i] == '\n')                            \
                                  formbuf[i] = '\r';                               \
                              printf (formbuf, ##__VA_ARGS__);                     \
                              }
# else
# define VPrint(...) printf (__VA_ARGS__)
# endif
#else
#define VPrint(...) vpi_printf (__VA_ARGS__)
#endif

#ifdef DEBUG
#define DebugVPrint VPrint
#else
#define DebugVPrint //
#endif

// Pointer to VUserMain function type definition
typedef void (*pVUserMain_t)(void);

#endif
