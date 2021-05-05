//=====================================================================
//
// VSched.c                                           Date: 2004/12/13
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
// $Id: VSched.c,v 1.5 2021/05/04 15:38:37 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/VSched.c,v $
//
//=====================================================================
//
// Simulator VProc C interface routines for scheduling
// access to user processes
//
// Only uses first generation PLI task/function (TF) routines
//
//=====================================================================

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include "VProc.h"
#include "VUser.h"
#include "VSched_pli.h"

// Pointers to state for each node (up to VP_MAX_NODES)
pSchedState_t ns[VP_MAX_NODES];

/////////////////////////////////////////////////////////////
// Main routine called whenever $vinit task invoked from
// initial block of VProc module.
//
VPROC_RTN_TYPE VInit (VINIT_PARAMS)
{
#ifndef VPROC_VHDL
    int node;
    pid_t pid;
    int fd;

    // Get single argument value of $vinit call
    node = tf_getp(VPNODENUM_ARG);
#endif

    debug_io_printf("VInit()\n");

    // Range check node number
    if (node < 0 || node >= VP_MAX_NODES) {
        io_printf("***Error: VInit() got out of range node number (%d)\n", node);
        exit(VP_USER_ERR);
    }

    debug_io_printf("VInit(): node = %d\n", node);

    // Allocate some space for the node state and update pointer
    ns[node] = (pSchedState_t) malloc(sizeof(SchedState_t));

    // Set up semaphores for this node
    debug_io_printf("VInit(): initialising semaphores for node %d\n", node);

    if (sem_init(&(ns[node]->snd), 0, 0) == -1) {
        io_printf("***Error: VInit() failed to initialise semaphore\n");
        exit(1);
    }
    if (sem_init(&(ns[node]->rcv), 0, 0) == -1) {
        io_printf("***Error: VInit() failed to initialise semaphore\n");
        exit(1);
    }

    debug_io_printf("VInit(): initialising semaphores for node %d---Done\n", node);

    // Issue a new thread to run the user code
    VUser(node);

#ifndef VPROC_VHDL
    return 0;
#endif
}

/////////////////////////////////////////////////////////////
// Called for a 'reason'. Holding procedure to catch 'finish'
// in case of any tidying up required.
//
int VHalt (int data, int reason)
{
    debug_io_printf("VHalt(): data = %d reason = %d\n", data, reason);

    if (reason == reason_endofcompile) {
    } else if (reason == reason_finish) {
#ifndef ICARUS
    } else if (reason == reason_startofsave) {
    } else if (reason == reason_save) {
    } else if (reason == reason_restart) {
        debug_io_printf("VHalt(): restart\n");
#endif
    } else if (reason != reason_finish) {
        debug_io_printf("VHalt(): not called for a halt reason (%d)\n", reason);
        return 0;
    }
}

/////////////////////////////////////////////////////////////
// Main routine called whenever $vsched task invoked, on
// clock edge of scheduled cycle.
//

VPROC_RTN_TYPE VSched (VSCHED_PARAMS)
{
    int VPDataOut_int, VPAddr_int, VPRw_int, VPTicks_int;

#ifndef VPROC_VHDL
    int node, Interrupt, VPDataIn;

    // Get the input argument values of $vsched
    node         = tf_getp (VPNODENUM_ARG);
    Interrupt    = tf_getp (VPINTERRUPT_ARG);
    VPDataIn     = tf_getp (VPDATAIN_ARG);
#endif

    // Sample inputs and update node state
    ns[node]->rcv_buf.data_in   = VPDataIn;
    ns[node]->rcv_buf.interrupt = Interrupt;

    // Send message to VUser with VPDataIn value
    debug_io_printf("VSched(): setting rcv[%d] semaphore\n", node);
    sem_post(&(ns[node]->rcv));

    // Wait for a message from VUser process with output data
    debug_io_printf("VSched(): waiting for snd[%d] semaphore\n", node);
    sem_wait(&(ns[node]->snd));

    // Update outputs of $vsched task
    if (ns[node]->send_buf.ticks >= DELTA_CYCLE) {
        VPDataOut_int = ns[node]->send_buf.data_out;
        VPAddr_int    = ns[node]->send_buf.addr;
        VPRw_int      = ns[node]->send_buf.rw;
        VPTicks_int   = ns[node]->send_buf.ticks;
        debug_io_printf("VSched(): VPTicks=%08x\n", VPTicks_int);
    }

    debug_io_printf("VSched(): Interrupt=%d VPDataIn=%08x VPDataOut=%08x VPAddr=%08x VPRw=%d VPTicks=%d\n", Interrupt, VPDataIn, VPDataOut_int, VPAddr_int, VPRw_int, VPTicks_int);

    debug_io_printf("VSched(): returning to simulation from node %d\n\n", node);

#ifdef VPROC_VHDL
    // Export outputs over FLI
    *VPDataOut = VPDataOut_int;
    *VPAddr    = VPAddr_int;
    *VPRw      = VPRw_int;
    *VPTicks   = VPTicks_int;

#else
    // Update verilog PLI task ($vsched) output values with returned update data
    tf_putp (VPDATAOUT_ARG, VPDataOut_int);
    tf_putp (VPADDR_ARG,    VPAddr_int);
    tf_putp (VPRW_ARG,      VPRw_int);
    tf_putp (VPTICKS_ARG,   VPTicks_int);

    return 0;
#endif

}

/////////////////////////////////////////////////////////////
// Calls a user registered function (if available) when
// $vprocuser(node) called in verilog
//
VPROC_RTN_TYPE VProcUser(VPROCUSER_PARAMS)
{
#ifndef VPROC_VHDL
    int node, value;

    node  = tf_getp (VPNODENUM_ARG);
    value = tf_getp (VPINTERRUPT_ARG);
#endif

    if (ns[node]->VUserCB != NULL)
        (*(ns[node]->VUserCB))(value);

#ifndef VPROC_VHDL
    return 0;
#endif
}

/////////////////////////////////////////////////////////////
// Called on $vaccess PLI task. Exchanges block data between
// C and verilog domain
//
VPROC_RTN_TYPE VAccess(VACCESS_PARAMS)
{
#ifdef VPROC_VHDL
    *VPDataOut                               = ((int *) ns[node]->send_buf.data_p)[idx];
    ((int *) ns[node]->send_buf.data_p)[idx] = VPDataIn;
#else
    int node, idx;

    node = tf_getp (VPNODENUM_ARG);
    idx  = tf_getp (VPINDEX_ARG);

    tf_putp (VPDATAOUT_ARG, ((int *) ns[node]->send_buf.data_p)[idx]);
    ((int *) ns[node]->send_buf.data_p)[idx] = tf_getp (VPDATAIN_ARG);

    return 0;
#endif
}
