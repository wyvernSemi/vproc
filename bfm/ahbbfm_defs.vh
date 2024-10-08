// ====================================================================
//
// Verilog AHB bus functional model (BFM) wrapper header for VProc.
//
// Copyright (c) 2024 Simon Southwell.
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

`define AHB_BFM_TRANS_IDLE        2'b00
`define AHB_BFM_TRANS_BUSY        2'b01
`define AHB_BFM_TRANS_NONSEQ      2'b10
`define AHB_BFM_TRANS_SEQ         2'b11

`define AHB_BFM_BURST_SINGLE      3'b000
`define AHB_BFM_BURST_INCR        3'b001
`define AHB_BFM_BURST_WRAP4       3'b010
`define AHB_BFM_BURST_INCR4       3'b011
`define AHB_BFM_BURST_WRAP8       3'b100
`define AHB_BFM_BURST_INCR8       3'b101
`define AHB_BFM_BURST_WRAP16      3'b110
`define AHB_BFM_BURST_INCR16      3'b111

`define AHB_BFM_SIZE_BYTE         3'b000
`define AHB_BFM_SIZE_HWORD        3'b001
`define AHB_BFM_SIZE_WORD         3'b010
`define AHB_BFM_SIZE_DWORD        3'b011
`define AHB_BFM_SIZE_QWORD        3'b100
`define AHB_BFM_SIZE_OWORD        3'b101
`define AHB_BFM_SIZE_WORD512      3'b110
`define AHB_BFM_SIZE_WORD1024     3'b111