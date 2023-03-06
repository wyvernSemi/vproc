//=====================================================================
//
// VProc.h                                            Date: 2004/12/13 
//
// Copyright (c) 2004-2010 Simon Southwell.
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
// $Id: VProc.h,v 1.3 2016/09/28 07:12:00 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/VProc.h,v $
//
//=====================================================================
//
// Internal header for VProc definitions and data types
//
//=====================================================================

#ifndef _VPROC_H_
#define _VPROC_H_

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>

#define __USE_GNU
#include <dlfcn.h>
#undef __USE_GNU
#include <pthread.h>
#include <sched.h>

#include <semaphore.h>

// For file IO
#include <fcntl.h>

// For inode manipulation
#include <unistd.h>

#ifndef VP_MAX_NODES
#define VP_MAX_NODES            64
#endif


#define M_TICK                  0x100
#define M_IO                    0x200
#define M_STOP                  0x300
#define M_PRINT                 0x400

#define V_IDLE                  0
#define V_WRITE                 1
#define V_READ                  2
#define V_HALT                  4
#define V_SWAP                  8

#define VP_EXIT_OK              0
#define VP_QUEUE_ERR            1
#define VP_KEY_ERR              2
#define VP_USER_ERR             3
#define VP_SYSCALL_ERR          4

#define UNDEF                   -1

#define VPNODENUM_ARG           1
#define VPINTERRUPT_ARG         2
#define VPDATAIN_ARG            3
#define VPDATAOUT_ARG           4
#define VPADDR_ARG              5
#define VPRW_ARG                6
#define VPTICKS_ARG             7

#define DEFAULT_STR_BUF_SIZE    32

#define MIN_INTERRUPT_LEVEL     1
#define MAX_INTERRUPT_LEVEL     7

#define MONITOR_SEG_SIZE        4096 

typedef unsigned short          uint16;
typedef unsigned int            uint32;
typedef unsigned long long      uint64;

typedef struct {
    unsigned int        addr;
    unsigned int        data_out;
    unsigned int        rw;
    void                *data_p;
    int                 ticks;
} send_buf_t, *psend_buf_t;

typedef struct {
    unsigned int        data_in;
    unsigned int        interrupt;
} rcv_buf_t, *prcv_buf_t;

typedef struct {
    int                 VPDataIn;
    int                 VPDataOut;
    int                 VPAddr;
    int                 VPTicks;
    short               VPRw;
    short               Interrupt;
} monitor_t, *pmonitor_t;

// Shared object handle type
typedef void * handle_t;

// Interrupt function pointer type
typedef int  (*pVUserInt_t)      (void);
typedef int  (*pVUserCB_t)       (int);

typedef struct {
    sem_t               snd;
    sem_t               rcv;
    send_buf_t          send_buf;
    rcv_buf_t           rcv_buf;
    pVUserInt_t         VInt_table[MAX_INTERRUPT_LEVEL+1];
    pVUserCB_t          VUserCB;
} SchedState_t, *pSchedState_t;

extern pSchedState_t ns[VP_MAX_NODES];

#endif
