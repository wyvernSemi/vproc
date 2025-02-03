//=====================================================================
//
// VUser.c                                            Date: 2004/12/13
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
// Top level VP user thread routines. Sets up connection to
// queue and calls relevant user function for node number.
//
//=====================================================================

#include <errno.h>
#include "VProc.h"
#include "VUser.h"

// Forward declaration
static void VUserInit (const unsigned node);

// =========================================================================
// Simulation interface functions
// =========================================================================

// -------------------------------------------------------------------------
// VUser()
//
// Entry point for new user process. Creates a new thread
// calling VUserInit().
// -------------------------------------------------------------------------

int VUser (const uint32_t node)
{
    pthread_t thread;
    int       status;
    int       idx, jdx;

    debug_io_printf("VUser(): node %d\n", node);

    // Level interrupt callback table initialisation
    for (jdx = 0; jdx < 8; jdx++)
    {
        ns[node]->VInt_table[jdx] = NULL;
    }

    // Callback intialisation
    ns[node]->VUserIrqCB = NULL;
    ns[node]->VUserCB    = NULL;

    debug_io_printf("VUser(): initialised callbacks at node %d\n", node);

    // Set off the user code thread using VUserInit to initialise before entering user code
    if (status = pthread_create(&thread, NULL, (pThreadFunc_t)VUserInit, (void *)((nodecast_t)node)))
    {
        debug_io_printf("VUser(): pthread_create returned %d\n", status);
        return 1;
    }

    debug_io_printf("VUser(): spawned user thread for node %d\n", node);

    return 0;
}

// -------------------------------------------------------------------------
// VUserInit()
//
// New thread initialisation procedure. Synchronises with
// simulation before calling user procedure.
// -------------------------------------------------------------------------

static void VUserInit (const uint32_t node)
{
    handle_t     hdl;
    pVUserMain_t VUserMain_func;
    char         funcname[DEFAULT_STR_BUF_SIZE];
    int          status;

    debug_io_printf("VUserInit(%d)\n", node);

    // Get function pointer of user entry routine
    sprintf(funcname, "%s%d",    "VUserMain", node);
    if ((VUserMain_func = (pVUserMain_t) dlsym(RTLD_DEFAULT, funcname)) == NULL)
    {
#ifndef VERILATOR
        // If the lookup failed, try loading the shared object immediately
        // and trying again. This addresses an issue seen with ModelSim on
        // Windows where the symbols are *sometimes* not loaded by this point.
        void* hdl = dlopen("VProc.so", RTLD_NOW);

        if ((VUserMain_func = (pVUserMain_t) dlsym(hdl, funcname)) == NULL)
#endif
        {
            VPrint("***Error: failed to find user code symbol %s (VUserInit)\n", funcname);
            exit(1);
        }
    }

    debug_io_printf("VUserInit(): got user function (%s) for node %d (%p)\n", funcname, node, VUserMain_func);

    // Wait for first message from simulator
    debug_io_printf("VUserInit(): waiting for first message semaphore rcv[%d]\n", node);

    if ((status = sem_wait(&(ns[node]->rcv))) == -1)
    {
        VPrint("***Error: bad sem_post status (%d) on node %d (VUserInit)\n", status, node);
        exit(1);
    }

    debug_io_printf("VUserInit(): calling user code for node %d\n", node);

    // Call user program
    debug_io_printf("VUserInit(): calling VUserMain%d\n", node);

    VUserMain_func();
}

// -------------------------------------------------------------------------
// VExch()
//
// Message exchange routine. Handles all messages to and from
// simulation process (apart from initialisation. Each sent
// message has a reply. Interrupt messages require that
// the original IO message reply is waited for again.
// -------------------------------------------------------------------------

static void VExch (psend_buf_t psbuf, prcv_buf_t prbuf, const uint32_t node)
{
    int status;
    // Send message to simulator
    ns[node]->send_buf = *psbuf;

    debug_io_printf("VExch(): setting snd[%d] semaphore\n", node);

    if ((status = sem_post(&(ns[node]->snd))) == -1)
    {
        VPrint("***Error: bad sem_post status (%d) on node %d (VExch)\n", status, node);
        exit(1);
    }

    do
    {
        // Wait for response message from simulator
        debug_io_printf("VExch(): waiting for rcv[%d] semaphore\n", node);
        sem_wait(&(ns[node]->rcv));

        *prbuf = ns[node]->rcv_buf;

        // Check if this is an interrupt
        if (prbuf->interrupt > 0)
        {
            debug_io_printf("VExch(): node %d processing interrupt (%d)\n", node, prbuf->interrupt);

            if (prbuf->interrupt > MAX_INTERRUPT_LEVEL)
            {
                VPrint("***Error: invalid interrupt level %d (VExch)\n", prbuf->interrupt);
                exit(1);
            }

            if (ns[node]->VInt_table[prbuf->interrupt] != NULL)
            {
                // Call user registered interrupt function
                psbuf->ticks       = (*(ns[node]->VInt_table[prbuf->interrupt]))();
                ns[node]->send_buf = *psbuf;

                debug_io_printf("VExch(): interrupt send_buf[node].ticks = %d\n", ns[node]->send_buf.ticks);
            }

            // Send new message to simulation
            debug_io_printf("VExch(): setting snd[%d] semaphore (interrupt)\n", node);

            if ((status = sem_post(&(ns[node]->snd))) == -1)
            {
                VPrint("***Error: bad sem_post status (%d) on node %d (VExch)\n", status, node);
                exit(1);
            }
        }
    // If the response was an interrupt, go back and wait for IO message response.
    // (This could be in the same cycle as the interrupt)
    }
    while (prbuf->interrupt > 0);

    debug_io_printf("VExch(): returning to user code from node %d\n", node);

}

// =========================================================================
// User API functions
// =========================================================================

// -------------------------------------------------------------------------
// VWrite
//
// Invokes a write message exchange
// -------------------------------------------------------------------------

int VWrite (const uint32_t addr, const uint32_t data, const int delta, const uint32_t node)
{
    return VWriteBE(addr, data, 0xf, delta, node);
}

// -------------------------------------------------------------------------
// VWriteBE
//
// Invokes a write message exchange with byte enables
// -------------------------------------------------------------------------

int VWriteBE (const uint32_t addr, const uint32_t data, const uint32_t be, const int delta, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr     = addr;
    sbuf.data_out = data;
    sbuf.ticks    = delta ? DELTA_CYCLE : 0;

    sbuf.rw       = 0;  // clear RW fields
    p_rw->write   = 1;
    p_rw->fbe     = be & 0xf;

    VExch(&sbuf, &rbuf, node);

    return rbuf.data_in ;
}

// -------------------------------------------------------------------------
// VRead()
//
// Invokes a read message exchange
// -------------------------------------------------------------------------

int VRead (const uint32_t addr, uint32_t *rdata, const int delta, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr     = addr;
    sbuf.data_out = 0;
    sbuf.ticks    = delta ? DELTA_CYCLE : 0;

    sbuf.rw       = 0;  // clear RW fields
    p_rw->read    = 1;
    p_rw->fbe     = 0xf;

    VExch(&sbuf, &rbuf, node);

    *rdata        = rbuf.data_in;

    return 0;
}

// -------------------------------------------------------------------------
// VBurstWrite()
//
// Invokes a burst write message exchange
// -------------------------------------------------------------------------

int VBurstWrite (const uint32_t addr, void *data, const uint32_t wordlen, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr      = addr;
    sbuf.data_out  = 0;
    sbuf.data_p    = data;
    sbuf.ticks     = 0;

    sbuf.rw        = 0;  // clear RW fields
    p_rw->write    = 1;
    p_rw->burstlen = wordlen & 0xfff;
    p_rw->fbe      = 0xf;
    p_rw->lbe      = 0xf;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VBurstWriteBE()
//
// Invokes a burst write message exchange with byte enables
// -------------------------------------------------------------------------

int VBurstWriteBE (const uint32_t addr, void *data, const uint32_t wordlen, const uint32_t fbe, const uint32_t lbe, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr      = addr;
    sbuf.data_out  = 0;
    sbuf.data_p    = data;
    sbuf.ticks     = 0;

    sbuf.rw        = 0;  // clear RW fields
    p_rw->write    = 1;
    p_rw->burstlen = wordlen & 0xfff;
    p_rw->fbe      = fbe & 0xf;
    p_rw->lbe      = lbe & 0xf;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VBurstRead()
//
// Invokes a burst read message exchange
// -------------------------------------------------------------------------

int VBurstRead (const uint32_t addr, void *data, const uint32_t wordlen, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr      = addr;
    sbuf.data_out  = 0;
    sbuf.data_p    = data;
    sbuf.ticks     = 0;

    sbuf.rw        = 0;  // clear RW fields
    p_rw->read     = 1;
    p_rw->burstlen = wordlen & 0xfff;
    p_rw->fbe      = 0xf;
    p_rw->lbe      = 0xf;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VWrite
//
// Invokes a 64-bit write message exchange
// -------------------------------------------------------------------------

int VWrite64 (const uint64_t addr, const uint64_t data, const int delta, const uint32_t node)
{
    return VWriteBE64(addr, data, 0xff, delta, node);
}

// -------------------------------------------------------------------------
// VWriteBE64
//
// Invokes a 64-bit write message exchange with byte enables
// -------------------------------------------------------------------------

int VWriteBE64 (const uint64_t addr, const uint64_t data, const uint32_t be, const int delta, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw  = (rw_t*)&sbuf.rw;

    sbuf.addr        = (uint32_t)(addr & 0xffffffffULL);
    sbuf.addr_hi     = (uint32_t)((addr >> 32) & 0xffffffffULL);
    sbuf.data_out    = (uint32_t)(data & 0xffffffffULL);
    sbuf.data_out_hi = (uint32_t)((data >> 32) & 0xffffffffULL);
    sbuf.ticks       = delta ? DELTA_CYCLE : 0;

    sbuf.rw          = 0;  // clear RW fields
    p_rw->write      = 1;
    p_rw->fbe        = be & 0xf;

    VExch(&sbuf, &rbuf, node);

    return rbuf.data_in ;
}

// -------------------------------------------------------------------------
// VRead64
//
// Invokes a 64-bit read message exchange
// -------------------------------------------------------------------------

int VRead64 (const uint64_t addr, uint64_t *rdata, const int delta, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw  = (rw_t*)&sbuf.rw;

    sbuf.addr        = (uint32_t)(addr & 0xffffffffULL);
    sbuf.addr_hi     = (uint32_t)((addr >> 32) & 0xffffffffULL);
    sbuf.data_out    = 0;
    sbuf.data_out_hi = 0;
    sbuf.ticks       = delta ? DELTA_CYCLE : 0;

    sbuf.rw          = 0;  // clear RW fields
    p_rw->read       = 1;
    p_rw->fbe        = 0xff;

    VExch(&sbuf, &rbuf, node);

    *rdata           = ((uint64_t)rbuf.data_in) | (((uint64_t)rbuf.data_in_hi) << 32);

    return 0;
}

// -------------------------------------------------------------------------
// VBurstWrite64
//
// Invokes a 64-bit burst write message exchange
// -------------------------------------------------------------------------

int VBurstWrite64 (const uint64_t addr, void *data, const uint32_t wordlen, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw   = (rw_t*)&sbuf.rw;

    sbuf.addr        = (uint32_t)(addr & 0xffffffffULL);
    sbuf.addr_hi     = (uint32_t)((addr >> 32) & 0xffffffffULL);
    sbuf.data_out    = 0;
    sbuf.data_out_hi = 0;
    sbuf.data_p      = data;
    sbuf.ticks       = 0;

    sbuf.rw          = 0;  // clear RW fields
    p_rw->write      = 1;
    p_rw->burstlen   = wordlen & 0xfff;
    p_rw->fbe        = 0xff;
    p_rw->lbe        = 0xff;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VBurstWriteBE64()
//
// Invokes a burst write message exchange with byte enables
// -------------------------------------------------------------------------

int VBurstWriteBE64 (const uint64_t addr, void *data, const uint32_t wordlen, const uint32_t fbe, const uint32_t lbe, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr        = (uint32_t)(addr & 0xffffffffULL);
    sbuf.addr_hi     = (uint32_t)((addr >> 32) & 0xffffffffULL);
    sbuf.data_out    = 0;
    sbuf.data_out_hi = 0;
    sbuf.data_p      = data;
    sbuf.ticks       = 0;

    sbuf.rw          = 0;  // clear RW fields
    p_rw->write      = 1;
    p_rw->burstlen   = wordlen & 0xfff;
    p_rw->fbe        = fbe & 0xff;
    p_rw->lbe        = lbe & 0xff;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VBurstRead64()
//
// Invokes a burst read message exchange
// -------------------------------------------------------------------------

int VBurstRead64 (const uint64_t addr, void *data, const uint32_t wordlen, const uint32_t node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;
    rw_t*      p_rw = (rw_t*)&sbuf.rw;

    sbuf.addr        = (uint32_t)(addr & 0xffffffffULL);
    sbuf.addr_hi     = (uint32_t)((addr >> 32) & 0xffffffffULL);
    sbuf.data_out    = 0;
    sbuf.data_out_hi = 0;
    sbuf.data_p      = data;
    sbuf.ticks       = 0;

    sbuf.rw          = 0;  // clear RW fields
    p_rw->read       = 1;
    p_rw->burstlen   = wordlen & 0xfff;
    p_rw->fbe        = 0xff;
    p_rw->lbe        = 0xff;

    VExch(&sbuf, &rbuf, node);

    return 0;
}


// -------------------------------------------------------------------------
// VTick()
//
// Invokes a tick message exchange
// -------------------------------------------------------------------------

int VTick (const unsigned ticks, const unsigned node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;

    sbuf.addr     = 0;
    sbuf.data_out = 0;
    sbuf.rw       = V_IDLE;
    sbuf.ticks    = ticks;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

// -------------------------------------------------------------------------
// VRegInterrupt()
//
// Registers a user function as an level interrupt callback. Deprecated in
// favour f vectored interrupts. Kept for backwards compatibility.
// -------------------------------------------------------------------------

void VRegInterrupt (const int level, const pVUserInt_t func, const unsigned node)
{
    debug_io_printf("VRegInterrupt(): at node %d, registering interrupt level %d\n", node, level);

    if (level < MIN_INTERRUPT_LEVEL || level >= MAX_INTERRUPT_LEVEL)
    {
        VPrint("***Error: attempt to register an out of range interrupt level (VRegInterrupt)\n");
        exit(1);
    }

    ns[node]->VInt_table[level] = func;
}

// -------------------------------------------------------------------------
// VRegIrq()
//
// Registers a user function as a vector IRQ callback
// -------------------------------------------------------------------------

void VRegIrq (const pVUserIrqCB_t func, const unsigned node)
{
    debug_io_printf("VRegIrq(): at node %d, registering irq callback\n", node);

    ns[node]->VUserIrqCB = func;
}

// -------------------------------------------------------------------------
// VRegIrqPy()
//
// Registers a python interface function as a vector IRQ
// callback
// -------------------------------------------------------------------------

void VRegIrqPy (const pPyIrqCB_t func, const unsigned node)
{
    ns[node]->PyIrqCB = func;
}

// -------------------------------------------------------------------------
// VRegUser()
//
// Registers a user function as a callback against
// $vprocuser
// -------------------------------------------------------------------------

void VRegUser (const pVUserCB_t func, const unsigned node)
{
    debug_io_printf("VRegFinish(): at node %d, registering finish callback function\n", node);

    ns[node]->VUserCB = func;
}

