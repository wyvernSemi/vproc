//=====================================================================
//
// VUser.c                                            Date: 2004/12/13
//
// Copyright (c) 2004-2024 Simon Southwell.
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

#ifdef WIN32
# include <windows.h>

// Map Linux dynamic loading calls to Windows equivalents
# define dlsym GetProcAddress
# define dlopen(_dll, _args) {LoadLibrary(_dll)}
# define dlerror() ""
# define dlclose FreeLibrary

# ifdef _WIN64
typedef long long nodecast_t;
# else
typedef long      nodecast_t;
# endif
#else
typedef long      nodecast_t;
#endif

// For Icarus
#ifdef ICARUS
# ifndef RTLD_DEFAULT
# define RTLD_DEFAULT ((void *) 0)
# endif
#endif

static void VUserInit (const unsigned node);

/////////////////////////////////////////////////////////////
// Entry point for new user process. Creates a new thread
// calling VUserInit().
//
int VUser (const unsigned node)
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

/////////////////////////////////////////////////////////////
// New thread initialisation procedure. Synchronises with
// simulation before calling user procedure.
//
static void VUserInit (const unsigned node)
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
        // If the lookup failed, try loading the shared object immediately
        // and trying again. This addresses an issue seen with ModelSim on
        // Windows where the symbols are *sometimes* not loaded by this point.
        void* hdl = dlopen("VProc.so", RTLD_NOW);

        if ((VUserMain_func = (pVUserMain_t) dlsym(hdl, funcname)) == NULL)
        {
            io_printf("***Error: failed to find user code symbol %s (VUserInit)\n", funcname);
            exit(1);
        }
    }

    debug_io_printf("VUserInit(): got user function (%s) for node %d (%x)\n", funcname, node, VUserMain_func);

    // Wait for first message from simulator
    debug_io_printf("VUserInit(): waiting for first message semaphore rcv[%d]\n", node);

    if ((status = sem_wait(&(ns[node]->rcv))) == -1)
    {
        io_printf("***Error: bad sem_post status (%d) on node %d (VUserInit)\n", status, node);
        exit(1);
    }

    debug_io_printf("VUserInit(): calling user code for node %d\n", node);

    // Call user program
    debug_io_printf("VUserInit(): calling VUserMain%d\n", node);

    VUserMain_func();
}

/////////////////////////////////////////////////////////////
// Message exchange routine. Handles all messages to and from
// simulation process (apart from initialisation. Each sent
// message has a reply. Interrupt messages require that
// the original IO message reply is waited for again.
//
static void VExch (psend_buf_t psbuf, prcv_buf_t prbuf, const unsigned node)
{
    int status;
    // Send message to simulator
    ns[node]->send_buf = *psbuf;

    debug_io_printf("VExch(): setting snd[%d] semaphore\n", node);

    if ((status = sem_post(&(ns[node]->snd))) == -1)
    {
        io_printf("***Error: bad sem_post status (%d) on node %d (VExch)\n", status, node);
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
                io_printf("***Error: invalid interrupt level %d (VExch)\n", prbuf->interrupt);
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
                io_printf("***Error: bad sem_post status (%d) on node %d (VExch)\n", status, node);
                exit(1);
            }
        }
    // If the response was an interrupt, go back and wait for IO message response.
    // (This could be in the same cycle as the interrupt)
    }
    while (prbuf->interrupt > 0);

    debug_io_printf("VExch(): returning to user code from node %d\n", node);

}

/////////////////////////////////////////////////////////////
// Invokes a write message exchange
//
int VWrite (const unsigned addr, const unsigned data, const int delta, const unsigned node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;

    sbuf.addr     = addr;
    sbuf.data_out = data;
    sbuf.rw       = V_WRITE;
    sbuf.ticks    = delta ? DELTA_CYCLE : 0;

    VExch(&sbuf, &rbuf, node);

    return rbuf.data_in ;
}

/////////////////////////////////////////////////////////////
// Invokes a read message exchange
//
int VRead (const unsigned addr, unsigned *rdata, const int delta, const unsigned node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;

    sbuf.addr     = addr;
    sbuf.data_out = 0;
    sbuf.rw       = V_READ;
    sbuf.ticks    = delta ? DELTA_CYCLE : 0;;

    VExch(&sbuf, &rbuf, node);

    *rdata        = rbuf.data_in;

    return 0;
}

/////////////////////////////////////////////////////////////
// Invokes a burst write message exchange
//
int VBurstWrite (const unsigned addr, void *data, const unsigned len, const unsigned node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;

    sbuf.addr     = addr;
    sbuf.data_out = 0;
    sbuf.data_p   = data;
    sbuf.rw       = V_WRITE | ((len & 0xfff) << 2);
    sbuf.ticks    = 0;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

/////////////////////////////////////////////////////////////
// Invokes a burst read message exchange
//
int VBurstRead (const unsigned int addr, void *data, const unsigned len, const unsigned node)
{
    rcv_buf_t  rbuf;
    send_buf_t sbuf;

    sbuf.addr     = addr;
    sbuf.data_out = 0;
    sbuf.data_p   = data;
    sbuf.rw       = V_READ | ((len & 0xfff) << 2);
    sbuf.ticks    = 0;

    VExch(&sbuf, &rbuf, node);

    return 0;
}

/////////////////////////////////////////////////////////////
// Invokes a tick message exchange
//
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

/////////////////////////////////////////////////////////////
// Registers a user function as an interrupt callback
//
void VRegInterrupt (const int level, const pVUserInt_t func, const unsigned node)
{
    debug_io_printf("VRegInterrupt(): at node %d, registering interrupt level %d\n", node, level);

    if (level < MIN_INTERRUPT_LEVEL || level >= MAX_INTERRUPT_LEVEL)
    {
        io_printf("***Error: attempt to register an out of range interrupt level (VRegInterrupt)\n");
        exit(1);
    }

    ns[node]->VInt_table[level] = func;
}

/////////////////////////////////////////////////////////////
// Registers a user function as a vector IRQ callback
//
void VRegIrq (const pVUserIrqCB_t func, const unsigned node)
{
    printf("VRegIrq(): at node %d, registering irq callback\n", node);

    ns[node]->VUserIrqCB = func;
}

/////////////////////////////////////////////////////////////
// Registers a python interface function as a vector IRQ
// callback
//
void VRegIrqPy (const pPyIrqCB_t func, const unsigned node)
{
    ns[node]->PyIrqCB = func;
}

/////////////////////////////////////////////////////////////
// Registers a user function as a callback against
// $vprocuser
//
void VRegUser (const pVUserCB_t func, const unsigned node)
{
    debug_io_printf("VRegFinish(): at node %d, registering finish callback function\n", node);

    ns[node]->VUserCB = func;
}

