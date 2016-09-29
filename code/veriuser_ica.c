//=====================================================================
//
// veriuser_ica.c                                     Date: 2002/07/10 
//
// Copyright (c) 2002-2010 Simon Southwell.
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
// $Id: veriuser_ica.c,v 1.2 2010-07-31 05:32:44 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProcThread/code/veriuser_ica.c,v $
//
//=====================================================================
// 
// PLI task/function registration table for plitask
// 
//=====================================================================

// Icarus Compile line
// gcc -shared code/VSched.c code/veriuser_ica.c -DICARUS\
//    -L /usr/lib -lveriuser -lvpi \
//    -I /usr/include/iverilog -o VSched.so

// Command line
// iverilog -o sim test.v f_VProc.v
// vvp -m ./VSched.so sim

//#include "vxl_veriuser.h"
#include "VSched_pli.h"

char *veriuser_version_str = "Virtual Processor PLI V0.1 Copyright (c) 2005 Simon Southwell.";

s_tfcell veriusertfs[4] =
{
    {usertask, 0, NULL, 0, VInit,     VHalt, "$vinit",     1},
    {usertask, 0, NULL, 0, VSched,    NULL,  "$vsched",    1},
    {usertask, 0, NULL, 0, VAccess,   NULL,  "$vaccess",   1},
    {usertask, 0, NULL, 0, VProcUser, NULL,  "$vprocuser", 1},
    {0} 
};

p_tfcell bootstrap ()
{
    return veriusertfs;
}

#ifdef ICARUS
static void veriusertfs_register(void)
{
    veriusertfs_register_table(veriusertfs);
}

void (*vlog_startup_routines[])() = { &veriusertfs_register, 0 };
#endif
