// ====================================================================
//
// SystemVerilog side Virtual Processor 64-bit, for running host
// programs as control in simulation.
//
// Copyright (c) 2025 Simon Southwell.
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

// The SystemVerilog VProc HDL is the same as the Verilog, 
// with DPI definitions included here

`define VPROC_SV

`ifndef VPROCDPI_INCLUDED
`include "vprocdpi.vh"
`endif
`include "vprocdpi64.vh"

`include "f_VProc64.v"