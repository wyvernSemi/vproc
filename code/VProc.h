//=====================================================================
//
// VProc.h                                            Date: 2004/12/13 
//
// Copyright (c) 2004-2025 Simon Southwell.
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
//
// Internal header for VProc definitions and data types
//
//=====================================================================

#ifndef _VPROC_H_
#define _VPROC_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <dlfcn.h>
#include <pthread.h>
#include <semaphore.h>

#define VERSION_STRING         "VProc version 2.0.0. Copyright (c) 2004-2025 Simon Southwell."

#ifndef VP_MAX_NODES
#define VP_MAX_NODES            64
#endif

// Definitions for accesses
#define V_IDLE                  0
#define V_WRITE                 1
#define V_READ                  2

// Error types
#define VP_USER_ERR             1

// Indexes for PLI VSched function arguments
#define VPNODENUM_ARG           1
#define VPDATAIN_ARG            2
#define VPDATAOUT_ARG           3
#define VPADDR_ARG              4
#define VPRW_ARG                5
#define VPTICKS_ARG             6

#define VPDATAINLO_ARG64        2
#define VPDATAINHI_ARG64        3
#define VPDATAOUTLO_ARG64       4
#define VPDATAOUTHI_ARG64       5
#define VPADDRLO_ARG64          6
#define VPADDRHI_ARG64          7
#define VPRW_ARG64              8
#define VPTICKS_ARG64           9

// Index for VIrq PLI function argument
#define VPINTERRUPT_ARG         2

// Indexes for VAccess PLI function arguments
#define VPINDEX_ARG             2
#define VPACCESSIN_ARG          3
#define VPACCESSOUT_ARG         4

// Indexes for VProcUser PLI function arguments
#define VP_USER_ARG             2

// A default string buffer size
#define DEFAULT_STR_BUF_SIZE    32

// Python interface interrupt queue definitions
#define NUM_IRQ_QUEUE_BITS      10
#define MAX_QUEUED_VEC_IRQ      (1 << NUM_IRQ_QUEUE_BITS)
#define IRQ_QUEUE_INDEX_MASK    (MAX_QUEUED_VEC_IRQ - 1)
#define IRQ_QUEUE_COUNT_MASK    (MAX_QUEUED_VEC_IRQ*2 - 1)

// Bitfield structure for rw value of send_buf_t exchange structure
typedef struct {
    uint32_t write    : 1;
    uint32_t read     : 1;
    uint32_t burstlen : 12;
    uint32_t fbe      : 8;
    uint32_t lbe      : 8;
    uint32_t rsvd     : 2;
} rw_t;


// User thread to simulation exchange structure
typedef struct {
    uint32_t            addr;
    uint32_t            addr_hi;
    uint32_t            data_out;
    uint32_t            data_out_hi;
    uint32_t            rw;
    void                *data_p;
    int                 ticks;
} send_buf_t, *psend_buf_t;

// Simulation to user thread exchange structure
typedef struct {
    uint32_t           data_in;
    uint32_t           data_in_hi;
} rcv_buf_t, *prcv_buf_t;

// Shared object handle typedef
typedef void * handle_t;

// Callback pointer types
typedef int  (*pVUserIrqCB_t)    (int);
typedef int  (*pPyIrqCB_t)       (int, int);
typedef int  (*pVUserCB_t)       (int);

// Python interface event queue structure
typedef struct {
    uint32_t eventPtr;
    uint32_t eventPopPtr;
    uint32_t eventQueue [MAX_QUEUED_VEC_IRQ];
} vecIrqState_t;

// Scheduler node state structure
typedef struct {
    // Send and receive semaphores
    sem_t               snd;
    sem_t               rcv;
    
    // Send and receive buffers
    send_buf_t          send_buf;
    rcv_buf_t           rcv_buf;
    
    // Callback function pointers
    pVUserIrqCB_t       VUserIrqCB;
    pPyIrqCB_t          PyIrqCB;
    pVUserCB_t          VUserCB;
    
    // Python IRQ event queue
    vecIrqState_t       irqState;
} SchedState_t, *pSchedState_t;

// Reference to node state array
extern pSchedState_t ns[];

#endif
