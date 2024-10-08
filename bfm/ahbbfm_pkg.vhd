-- ====================================================================
--
-- VHDL AHB bus functional model (BFM) wrapper package for VProc.
--
-- Copyright (c) 2024 Simon Southwell.
--
-- This file is part of VProc.
--
-- VProc is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- VProc is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with VProc. If not, see <http://www.gnu.org/licenses/>.
--
-- ====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ahbbfm_pkg is

constant AHB_BFM_TRANS_IDLE        : std_logic_vector := "00" ;
constant AHB_BFM_TRANS_BUSY        : std_logic_vector := "01" ;
constant AHB_BFM_TRANS_NONSEQ      : std_logic_vector := "10" ;
constant AHB_BFM_TRANS_SEQ         : std_logic_vector := "11" ;

constant AHB_BFM_BURST_SINGLE      : std_logic_vector := "000";
constant AHB_BFM_BURST_INCR        : std_logic_vector := "001";
constant AHB_BFM_BURST_WRAP4       : std_logic_vector := "010";
constant AHB_BFM_BURST_INCR4       : std_logic_vector := "011";
constant AHB_BFM_BURST_WRAP8       : std_logic_vector := "100";
constant AHB_BFM_BURST_INCR8       : std_logic_vector := "101";
constant AHB_BFM_BURST_WRAP16      : std_logic_vector := "110";
constant AHB_BFM_BURST_INCR16      : std_logic_vector := "111";

constant AHB_BFM_SIZE_BYTE         : std_logic_vector := "000";
constant AHB_BFM_SIZE_HWORD        : std_logic_vector := "001";
constant AHB_BFM_SIZE_WORD         : std_logic_vector := "010";
constant AHB_BFM_SIZE_DWORD        : std_logic_vector := "011";
constant AHB_BFM_SIZE_QWORD        : std_logic_vector := "100";
constant AHB_BFM_SIZE_OWORD        : std_logic_vector := "101";
constant AHB_BFM_SIZE_WORD512      : std_logic_vector := "110";
constant AHB_BFM_SIZE_WORD1024     : std_logic_vector := "111";

end;