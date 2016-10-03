//=====================================================================
//
// veriuser.c                                         Date: 2002/07/10 
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
// $Id: veriuser.c,v 1.4 2016/10/03 13:21:41 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProc/code/veriuser.c,v $
//
//=====================================================================
// 
// PLI task/function registration table for plitask
// 
//=====================================================================

#if !defined(MODELSIM)
#include "vxl_veriuser.h"
#endif
#include "VSched_pli.h"

char *veriuser_version_str = "Virtual Processor PLI V0.1 Copyright (c) 2005 Simon Southwell.";

s_tfcell veriusertfs[5] =
{
    VPROC_TF_TBL,
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
