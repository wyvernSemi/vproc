//=====================================================================
//
// VSched.c                                           Date: 2004/12/13
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

#if defined(VPROC_VHDL_VHPI)

// -------------------------------------------------------------------------
// Function setting up table of foreign procedure registration data
// and registering with VHPI
// -------------------------------------------------------------------------

VPROC_RTN_TYPE reg_foreign_procs() {
    int idx;
    vhpiForeignDataT foreignDataArray[] = {
        {vhpiProcF, (char*)"VProc", (char*)"VInit",           NULL, VInit},
        {vhpiProcF, (char*)"VProc", (char*)"VSched",          NULL, VSched},
        {vhpiProcF, (char*)"VProc", (char*)"VProcUser",       NULL, VProcUser},
        {vhpiProcF, (char*)"VProc", (char*)"VIrq",            NULL, VIrq},
        {vhpiProcF, (char*)"VProc", (char*)"VAccess",         NULL, VAccess},
        {0}
    };

    for (idx = 0; idx < ((sizeof(foreignDataArray)/sizeof(foreignDataArray[0]))-1); idx++)
    {
        vhpi_register_foreignf(&(foreignDataArray[idx]));
    }
}

// -------------------------------------------------------------------------
// List of user startup functions to call
// -------------------------------------------------------------------------
#ifdef WIN32
__declspec ( dllexport )
#endif

VPROC_RTN_TYPE (*vhpi_startup_routines[])() = {
    reg_foreign_procs,
    0L
};

// -------------------------------------------------------------------------
// getVhpiParams()
//
// Get the parameter values of a foreign procedure using VHPI methods
//
// -------------------------------------------------------------------------

static void getVhpiParams(const struct vhpiCbDataS* cb, int args[], int args_size)
{
    int         idx      = 0;
    vhpiValueT  value;

    vhpiHandleT hParam;
    vhpiHandleT hScope   = cb->obj;
    vhpiHandleT hIter    = vhpi_iterator(vhpiParamDecls, hScope);

    while ((hParam = vhpi_scan(hIter)) && idx < args_size)
    {
        value.format     = vhpiIntVal;
        value.bufSize    = 0;
        value.value.intg = 0;
        vhpi_get_value(hParam, &value);
        args[idx++]      = value.value.intg;
        DebugVPrint("getVhpiParams(): %s = %d\n", vhpi_get_str(vhpiNameP, hParam), value.value.intg);
    }
}

// -------------------------------------------------------------------------
// setVhpiParams()
//
// Set the parameters values of a foreign procedure using VHPI methods
//
// -------------------------------------------------------------------------

static void setVhpiParams(const struct vhpiCbDataS* cb, int args[], int start_of_outputs, int args_size)
{
    int         idx      = 0;
    vhpiValueT  value;

    vhpiHandleT hParam;
    vhpiHandleT hScope   = cb->obj;
    vhpiHandleT hIter    = vhpi_iterator(vhpiParamDecls, hScope);

    while ((hParam = vhpi_scan(hIter)) && idx < args_size)
    {
        if (idx >= start_of_outputs)
        {
            DebugVPrint("setVhpiParams(): %s = %d\n", vhpi_get_str(vhpiNameP, hParam), args[idx]);
            value.format     = vhpiIntVal;
            value.bufSize    = 0;
            value.value.intg = args[idx];
            vhpi_put_value(hParam, &value, vhpiDeposit);
        }
        idx++;
    }
}

#endif

// If not VHDL FLI, VHDL VHPI or PLI TF, use VPI
#if !defined (VPROC_VHDL) && !defined(VPROC_VHDL_VHPI) && defined(VPROC_PLI_VPI)

/////////////////////////////////////////////////////////////
// Registers the VProc system tasks
//
void register_vpi_tasks()
{
    s_vpi_systf_data data[] =
      {{vpiSysTask, 0, "$vinit",     VInit,     0, 0, 0},
       {vpiSysTask, 0, "$vsched",    VSched,    0, 0, 0},
       {vpiSysTask, 0, "$vaccess",   VAccess,   0, 0, 0},
       {vpiSysTask, 0, "$vprocuser", VProcUser, 0, 0, 0},
       {vpiSysTask, 0, "$virq",      VIrq,      0, 0, 0},
      };


    for (int idx= 0; idx < sizeof(data)/sizeof(s_vpi_systf_data); idx++)
    {
        debug_io_printf("registering %s\n", data[idx].tfname);
        vpi_register_systf(&data[idx]);
    }
}

/////////////////////////////////////////////////////////////
// Contains a zero-terminated list of functions that have
// to be called at startup
//
void (*vlog_startup_routines[])() =
{
    register_vpi_tasks,
    0
};

/////////////////////////////////////////////////////////////
// Get task arguments using VPI calls
//
static int getArgs (vpiHandle taskHdl, int value[])
{
  int                  idx = 0;
  struct t_vpi_value   argval;
  vpiHandle            argh;

  vpiHandle            args_iter = vpi_iterate(vpiArgument, taskHdl);

  while (argh = vpi_scan(args_iter))
  {
    argval.format      = vpiIntVal;

    vpi_get_value(argh, &argval);
    value[idx]         = argval.value.integer;

    debug_io_printf("VPI routine received %x at offset %d\n", value[idx++], idx);
  }

  return idx;
}

/////////////////////////////////////////////////////////////
// Update task arguments using VPI calls
//
static int updateArgs (vpiHandle taskHdl, int value[])
{
  int                 idx = 0;
  struct t_vpi_value  argval;
  vpiHandle           argh;

  vpiHandle           args_iter = vpi_iterate(vpiArgument, taskHdl);

  while (argh = vpi_scan(args_iter))
  {
    argval.format        = vpiIntVal;
    argval.value.integer = value[idx++];

    vpi_put_value(argh, &argval, NULL, vpiNoDelay);
  }

  return idx;
}

#endif

/////////////////////////////////////////////////////////////
// Main routine called whenever $vinit task invoked from
// initial block of VProc module.
//
VPROC_RTN_TYPE VInit (VINIT_PARAMS)
{

#ifndef VPROC_VHDL
    int node;

# ifndef VPROC_PLI_VPI

    // Get single argument value of $vinit call
    node = tf_getp(VPNODENUM_ARG);
    io_printf("VInit(%d): initialising PLI TF interface\n", node);

# else
    int                args[10];
    vpiHandle          taskHdl;

    // Obtain a handle to the argument list
    taskHdl            = vpi_handle(vpiSysTfCall, NULL);

    getArgs(taskHdl, &args[1]);

    // Get single argument value of $vinit call
    node = args[VPNODENUM_ARG];

    vpi_printf("VInit(%d): initialising VPI interface\n", node);



# endif
#else
# ifdef VPROC_VHDL_VHPI
    int node;
    int args[10];

    getVhpiParams(cb, &args[1], VINIT_NUM_ARGS);

    // Get single argument value of $vinit call
    node = args[VPNODENUM_ARG];

    VPrint("VInit(%d): initialising VHPI interface\n", node);
# else
    VPrint("VInit(%d): initialising FLI interface\n", node);
# endif
#endif

    debug_io_printf("VInit()\n");

    // Range check node number
    if (node < 0 || node >= VP_MAX_NODES)
    {
        io_printf("***Error: VInit() got out of range node number (%d)\n", node);
        exit(VP_USER_ERR);
    }

    debug_io_printf("VInit(): node = %d\n", node);

    // Allocate some space for the node state and update pointer
    ns[node] = (pSchedState_t) malloc(sizeof(SchedState_t));

    // Set up semaphores for this node
    debug_io_printf("VInit(): initialising semaphores for node %d\n", node);

    if (sem_init(&(ns[node]->snd), 0, 0) == -1)
    {
        io_printf("***Error: VInit() failed to initialise semaphore\n");
        exit(1);
    }
    if (sem_init(&(ns[node]->rcv), 0, 0) == -1)
    {
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
    int args[10];

#ifndef VPROC_VHDL

    int node;
    int Interrupt, VPDataIn;

# ifndef VPROC_PLI_VPI

    // Get the input argument values of $vsched
    node         = tf_getp (VPNODENUM_ARG);
    Interrupt    = tf_getp (VPINTERRUPT_ARG);
    VPDataIn     = tf_getp (VPDATAIN_ARG);

# else

    vpiHandle    taskHdl;

    // Obtain a handle to the argument list
    taskHdl      = vpi_handle(vpiSysTfCall, NULL);

    getArgs(taskHdl, &args[1]);

    // Get single argument value of $vinit call
    node         = args[VPNODENUM_ARG];
    Interrupt    = args[VPINTERRUPT_ARG];
    VPDataIn     = args[VPDATAIN_ARG];

# endif

#else

# ifdef VPROC_VHDL_VHPI

    int node;
    int Interrupt, VPDataIn;

    getVhpiParams(cb, &args[1], VSCHED_NUM_ARGS);

# endif
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
    if (ns[node]->send_buf.ticks >= DELTA_CYCLE)
    {
        VPDataOut_int = ns[node]->send_buf.data_out;
        VPAddr_int    = ns[node]->send_buf.addr;
        VPRw_int      = ns[node]->send_buf.rw;
        VPTicks_int   = ns[node]->send_buf.ticks;
        debug_io_printf("VSched(): VPTicks=%08x\n", VPTicks_int);
    }

    debug_io_printf("VSched(): returning to simulation from node %d\n\n", node);

#ifdef VPROC_VHDL
#  ifndef VPROC_VHDL_VHPI

    // Export outputs over FLI
    *VPDataOut = VPDataOut_int;
    *VPAddr    = VPAddr_int;
    *VPRw      = VPRw_int;
    *VPTicks   = VPTicks_int;
#   else
    args[VPDATAOUT_ARG] = VPDataOut_int;
    args[VPADDR_ARG]    = VPAddr_int;
    args[VPRW_ARG]      = VPRw_int;
    args[VPTICKS_ARG]   = VPTicks_int;

    setVhpiParams(cb, &args[1], VPDATAOUT_ARG-1, VSCHED_NUM_ARGS);
#   endif

#else
# ifndef VPROC_PLI_VPI
    // Update verilog PLI task ($vsched) output values with returned update data
    tf_putp (VPDATAOUT_ARG, VPDataOut_int);
    tf_putp (VPADDR_ARG,    VPAddr_int);
    tf_putp (VPRW_ARG,      VPRw_int);
    tf_putp (VPTICKS_ARG,   VPTicks_int);
# else
    args[VPDATAOUT_ARG] = VPDataOut_int;
    args[VPADDR_ARG]    = VPAddr_int;
    args[VPRW_ARG]      = VPRw_int;
    args[VPTICKS_ARG]   = VPTicks_int;

    updateArgs(taskHdl, &args[1]);
# endif

    return 0;
#endif

}

/////////////////////////////////////////////////////////////
// Calls a user registered function (if available) when
// $vprocuser(node, value) called in verilog
//
VPROC_RTN_TYPE VProcUser(VPROCUSER_PARAMS)
{
#ifndef VPROC_VHDL

    int node, value;

# ifndef VPROC_PLI_VPI

    node      = tf_getp (VPNODENUM_ARG);
    value     = tf_getp (VPINTERRUPT_ARG);

# else
    vpiHandle taskHdl;
    int       args[10];

    // Obtain a handle to the argument list
    taskHdl   = vpi_handle(vpiSysTfCall, NULL);

    getArgs(taskHdl, &args[1]);

    // Get argument values of $vprocuser call
    node      = args[VPNODENUM_ARG];
    value     = args[VPINTERRUPT_ARG];

# endif
#else
# ifdef VPROC_VHDL_VHPI

     int      node, value;
    int       args[10];

    getVhpiParams(cb, &args[1], VPROCUSER_NUM_ARGS);

    // Get argument values of VProcUser VHPI call
    node      = args[VPNODENUM_ARG];
    value     = args[VPINTERRUPT_ARG];

# endif
#endif

    if (ns[node]->VUserCB != NULL)
    {
        (*(ns[node]->VUserCB))(value);
    }

#ifndef VPROC_VHDL
    return 0;
#endif
}

/////////////////////////////////////////////////////////////
// Calls a irq registered function (if available) when
// $virq(node, irq) called in verilog
//
VPROC_RTN_TYPE VIrq(VIRQ_PARAMS)
{
#ifndef VPROC_VHDL

    int node, value;

# ifndef VPROC_PLI_VPI

    node      = tf_getp (VPNODENUM_ARG);
    value     = tf_getp (VPINTERRUPT_ARG);

# else
    vpiHandle taskHdl;
    int       args[10];

    // Obtain a handle to the argument list
    taskHdl   = vpi_handle(vpiSysTfCall, NULL);

    getArgs(taskHdl, &args[1]);

    // Get argument values of $vprocuser call
    node      = args[VPNODENUM_ARG];
    value     = args[VPINTERRUPT_ARG];

# endif
#else
# ifdef VPROC_VHDL_VHPI

    int       node, value;
    int       args[10];

    getVhpiParams(cb, &args[1], VPROCUSER_NUM_ARGS);

    // Get argument values of VProcUser VHPI call
    node      = args[VPNODENUM_ARG];
    value     = args[VPINTERRUPT_ARG];

# endif
#endif

    if (ns[node]->VUserIrqCB != NULL)
    {
        (*(ns[node]->VUserIrqCB))(value);
    }

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
    int       args[10];

#ifdef VPROC_VHDL
# ifndef VPROC_VHDL_VHPI
    *VPDataOut                               = ((int *) ns[node]->send_buf.data_p)[idx];
    ((int *) ns[node]->send_buf.data_p)[idx] = VPDataIn;
# else

    int node, idx;

    getVhpiParams(cb, &args[1], VACCESS_NUM_ARGS);

    node      = args[VPNODENUM_ARG];
    idx       = args[VPINDEX_ARG];

    args[VPDATAOUT_ARG] = ((int *) ns[node]->send_buf.data_p)[idx];

    ((int *) ns[node]->send_buf.data_p)[idx] = args[VPDATAIN_ARG];

    setVhpiParams(cb, &args[1], VPDATAOUT_ARG-1, VACCESS_NUM_ARGS);

# endif

#else

   int node, idx;

# ifndef VPROC_PLI_VPI
    node      = tf_getp (VPNODENUM_ARG);
    idx       = tf_getp (VPINDEX_ARG);

    tf_putp (VPDATAOUT_ARG, ((int *) ns[node]->send_buf.data_p)[idx]);
    ((int *) ns[node]->send_buf.data_p)[idx] = tf_getp (VPDATAIN_ARG);

# else
    vpiHandle taskHdl;

    // Obtain a handle to the argument list
    taskHdl   = vpi_handle(vpiSysTfCall, NULL);

    getArgs(taskHdl, &args[1]);

    node      = args[VPNODENUM_ARG];
    idx       = args[VPINDEX_ARG];

    args[VPDATAOUT_ARG] = ((int *) ns[node]->send_buf.data_p)[idx];

    ((int *) ns[node]->send_buf.data_p)[idx] = args[VPDATAIN_ARG];

    updateArgs(taskHdl, &args[1]);

# endif

    return 0;
#endif
}
