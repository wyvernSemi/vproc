//=====================================================================
//
// veriuser.c                                         Date: 2002/07/10 
//
// Copyright (c) 2002-2024 Simon Southwell.
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
// PLI task/function registration table for plitask
// 
//=====================================================================

#include "VSched_pli.h"

#ifndef VPROC_PLI_VPI

#ifndef MEM_MODEL_TF_TBL
#define MEM_MODEL_TF_TBL {0},
#endif

char *veriuser_version_str = "Virtual Processor PLI V0.1 Copyright (c) 2005 Simon Southwell.";

s_tfcell veriusertfs[] =
{
    VPROC_TF_TBL,
    MEM_MODEL_TF_TBL
    {0} 
};

p_tfcell bootstrap ()
{
    return veriusertfs;
}

# ifdef ICARUS
static void veriusertfs_register(void)
{
    veriusertfs_register_table(veriusertfs);
}

void (*vlog_startup_routines[])() = { &veriusertfs_register, 0 };
# endif
#endif