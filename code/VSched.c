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
// $Id: VSched.c,v 1.3 2016-09-29 08:47:53 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProcThread/code/VSched.c,v $
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
int VInit ()
{
    int node;
    pid_t pid;
    int fd;

    debug_io_printf("VInit()\n");

    // Get single argument value of $vinit call
    node = tf_getp(VPNODENUM_ARG);
   
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

    return 0;
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
    } else if (reason == reason_startofsave) {
    } else if (reason == reason_save) {
    } else if (reason == reason_restart) {
        debug_io_printf("VHalt(): restart\n");
    } else if (reason != reason_finish) {
        debug_io_printf("VHalt(): not called for a halt reason (%d)\n", reason);
        return 0;
    }
}

/////////////////////////////////////////////////////////////
// Main routine called whenever $vsched task invoked, on 
// clock edge of scheduled cycle.
//

int VSched ()
{
    int node, Interrupt, VPDataIn;
    int VPDataOut, VPAddr, VPRw, VPTicks;
 
    // Get the input argumant values of $vsched
    node         = tf_getp (VPNODENUM_ARG);
    Interrupt    = tf_getp (VPINTERRUPT_ARG);
    VPDataIn     = tf_getp (VPDATAIN_ARG);

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
        VPDataOut = ns[node]->send_buf.data_out;
        VPAddr    = ns[node]->send_buf.addr;
        VPRw      = ns[node]->send_buf.rw;
        VPTicks   = ns[node]->send_buf.ticks;
        debug_io_printf("VSched(): VPTicks=%08x\n", VPTicks);
    } 

    debug_io_printf("VSched(): Interrupt=%d VPDataIn=%08x VPDataOut=%08x VPAddr=%08x VPRw=%d VPTicks=%d\n", Interrupt, VPDataIn, VPDataOut, VPAddr, VPRw, VPTicks);

    debug_io_printf("VSched(): returning to simulation from node %d\n\n", node);

    // Update verilog PLI task ($vsched) output values with returned update data
    tf_putp (VPDATAOUT_ARG, VPDataOut);
    tf_putp (VPADDR_ARG,    VPAddr);
    tf_putp (VPRW_ARG,      VPRw);
    tf_putp (VPTICKS_ARG,   VPTicks);

    return 0;
}

/////////////////////////////////////////////////////////////
// Calls a user registered function (if available) when
// $vprocuser(node) called in verilog
//
int VProcUser()
{
    int node, value;

    node  = tf_getp (VPNODENUM_ARG);
    value = tf_getp (VPINTERRUPT_ARG);

    if (ns[node]->VUserCB != NULL) 
        (*(ns[node]->VUserCB))(value);

    return 0;
}

/////////////////////////////////////////////////////////////
// Called on $vaccess PLI task. Exchanges block data between
// C and verilog domain
//
int VAccess()
{
    int node, idx;

    node = tf_getp (VPNODENUM_ARG);
    idx  = tf_getp (VPINDEX_ARG);

    tf_putp (VPDATAOUT_ARG, ((int *) ns[node]->send_buf.data_p)[idx]);
    ((int *) ns[node]->send_buf.data_p)[idx] = tf_getp (VPDATAIN_ARG);

    return 0;
}
