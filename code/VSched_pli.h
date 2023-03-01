//=====================================================================
//
// VSched_pli.h                                       Date: 2004/12/13
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
// $Id: VSched_pli.h,v 1.5 2021/05/15 07:45:17 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/VSched_pli.h,v $
//
//=====================================================================
//
// VSched function's export prototypes
//
//=====================================================================

#include "string.h"

#include "aldecpli.h"
#include "veriuser.h"
#include "vpi_user.h"

#ifdef INCL_VLOG_MEM_MODEL
#include "mem_model.h"
#endif

#ifndef _VSCHED_PLI_H_
#define _VSCHED_PLI_H_
#define _VSCHED_PLI_H_

# ifndef VPROC_PLI_VPI

#define VPROC_TF_TBL \
    {usertask, 0, NULL, 0, VInit,     NULL, "$vinit",     1}, \
    {usertask, 0, NULL, 0, VSched,    NULL, "$vsched",    1}

#define VPROC_TF_TBL_SIZE 2

#define VINIT_PARAMS      void
#define VSCHED_PARAMS     void
#define VPROCUSER_PARAMS  void
#define VACCESS_PARAMS    void
#define VHALT_PARAMS      int data, int reason

#define VPROC_RTN_TYPE    int

# else
#define VPROC_VPI_TBL \
       {vpiSysTask, 0, "$vinit",     VInit,     0, 0, 0}, \
       {vpiSysTask, 0, "$vsched",    VSched,    0, 0, 0}

#define VPROC_VPI_TBL_SIZE 2
#define VPROC_TF_TBL_SIZE  1
#define VPROC_TF_TBL       {0}

#define VINIT_PARAMS      char* userdata
#define VSCHED_PARAMS     char* userdata
#define VPROCUSER_PARAMS  char* userdata
#define VACCESS_PARAMS    char* userdata
#define VHALT_PARAMS      int data, int reason

#define VPROC_RTN_TYPE    int

# endif


extern VPROC_RTN_TYPE VInit     (VINIT_PARAMS);
extern VPROC_RTN_TYPE VSched    (VSCHED_PARAMS);

#endif
