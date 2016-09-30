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
// $Id: VSched_pli.h,v 1.2 2016-09-30 12:28:14 simon Exp $
// $Source: /home/simon/CVS/src/HDL/VProcThread/code/VSched_pli.h,v $
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

extern int VInit     (void);
extern int VSched    (void);
extern int VPrinter  (void);
extern int VHalt     (int, int);
extern int VProcUser (void);
extern int VAccess   (void);
