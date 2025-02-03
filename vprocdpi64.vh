// ====================================================================
//
// Verilog side Virtual Processor 64-bit, for running host
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

// Import DPI-C fuctions

import "DPI-C" function void VSched64  (input  int node,
                                        input  int Interrupt,
                                        input  int VPDataInLo,
                                        input  int VPDataInHi,
                                        output int VPDataOutLo,
                                        output int VPDataOutHi,
                                        output int VPAddrLo,
                                        output int VPAddrHi,
                                        output int VPRw,
                                        output int VPTicks);
