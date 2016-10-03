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
// $Id: VSched_pli.h,v 1.3 2016/10/03 13:20:56 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/VSched_pli.h,v $
//
//=====================================================================
//
// VSched function's export prototypes
//
//=====================================================================

#include "string.h"
#include "veriuser.h"
#include "vpi_user.h"

#ifdef DEBUG
#define debug_io_printf io_printf
#else
#define debug_io_printf //
#endif

#define VPROC_TF_TBL \
    {usertask, 0, NULL, 0, VInit,     VHalt, "$vinit",     1}, \
    {usertask, 0, NULL, 0, VSched,    NULL,  "$vsched",    1}, \
    {usertask, 0, NULL, 0, VAccess,   NULL,  "$vaccess",   1}, \
    {usertask, 0, NULL, 0, VProcUser, NULL,  "$vprocuser", 1}

#define VPROC_TF_TBL_SIZE 4

extern int VInit     (void);
extern int VSched    (void);
extern int VPrinter  (void);
extern int VHalt     (int, int);
extern int VProcUser (void);
extern int VAccess   (void);
