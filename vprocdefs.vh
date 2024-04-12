// ====================================================================
//
// User defined Extra definitions for verilog compilation
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
// ====================================================================

`include "extradefs.v"

`VProcTimeScale

// Bit definitions
`define WEBIT                   0
`define RDBIT                   1
`define BLKBITS                 13:2

`define DELTACYCLE              -1
`define DONTCARE                 0

`ifndef VERILATOR
`define MINDELAY                 #0
`else
`define MINDELAY                 /**/
`endif
