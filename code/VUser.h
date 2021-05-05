//=====================================================================
//
// VUser.h                                            Date: 2005/01/10 
//
// Copyright (c) 2005-2010 Simon Southwell.
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
// $Id: VUser.h,v 1.5 2021/05/04 15:38:37 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/VUser.h,v $
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

// Pointer to pthread_create compatible function
typedef void *(*pThreadFunc_t)(void *);

// VUser function prototypes
extern int  VUser         (int node);
extern int  VWrite        (unsigned int addr, unsigned int  data, int delta, unsigned int node);
extern int  VRead         (unsigned int addr, unsigned int *data, int delta, unsigned int node);
extern int  VSwap         (unsigned int addr, void         *data, int delta, unsigned int node);
extern int  VTick         (unsigned int ticks, unsigned int node);
extern void VRegInterrupt (int level, pVUserInt_t func, unsigned int node);
extern void VRegUser      (pVUserCB_t func, uint32 node);

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
