/*
 * User defined Extra definitions for verilog compilation
 *
 * Copyright (c) 2004-2010 Simon Southwell. 
 *
 * This file is part of VProc.
 *
 * VProc is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * VProc is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with VProc. If not, see <http://www.gnu.org/licenses/>.
 *
 * $Id: extradefs.v,v 1.1 2010/06/18 15:33:44 simon Exp $
 * $Source: /home/simon/CVS/src/HDL/VProc/extradefs.v,v $
 */

`define VProcTimeScale `timescale 1 ps / 1 ps
`ifndef RegDel
`define RegDel 200
`endif
