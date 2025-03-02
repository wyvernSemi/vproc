-- ====================================================================
--
-- VHDL side Virtual Processor, for running host
-- programs as control in simulation.
--
-- Copyright (c) 2025 Simon Southwell.
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

-- ============================================================
-- vproc2 component
-- ============================================================

entity vproc2 is
generic (                              ARCH_WIDTH      : integer range 32 to 64 := 32;
                                       INT_WIDTH       : integer range  1 to 32 := 32;
                                       NODE            : integer range  0 to 15 := 0;
                                       BURST_ADDR_INCR : integer range  1 to 8  := 1;
                                       DISABLE_DELTA   : integer range  0 to 1  := 0
);
port (
    -- Clock
    clk                                : in  std_logic;

    -- Bus interface
    addr                               : out std_logic_vector (ARCH_WIDTH-1   downto 0) := (others => '0');
    be                                 : out std_logic_vector (ARCH_WIDTH/8-1 downto 0) := (others => '0');
    wr                                 : out std_logic                                  := '0';
    rd                                 : out std_logic                                  := '0';
    data_out                           : out std_logic_vector (ARCH_WIDTH-1   downto 0);
    data_in                            : in  std_logic_vector (ARCH_WIDTH-1   downto 0);
    wrack                              : in  std_logic                                  := '0';
    rdack                              : in  std_logic                                  := '0';

    -- Interrupt
    irq                                : in  std_logic_vector(INT_WIDTH-1    downto 0)  := (others => '0');

    -- Delta cycle control
    update                             : out std_logic                                  := '0';
    update_response                    : in  std_logic                                  := '0';

    -- Burst count and flags
    burst                              : out std_logic_vector (11 downto 0)             := 12x"000";
    burst_first                        : out std_logic                                  := '0';
    burst_last                         : out std_logic                                  := '0'
);

end;

architecture behavioural of vproc2 is

constant NODE_WIDTH                    : integer := 4;

begin

g_VPROC : if ARCH_WIDTH = 32 generate


  -- ---------------------------------------------------------
  -- Virtual Processor 32-bit
  -- ---------------------------------------------------------

  vp32 : entity work.VProc
  generic map (
   INT_WIDTH                           => INT_WIDTH,
   NODE_WIDTH                          => NODE_WIDTH,
   BURST_ADDR_INCR                     => BURST_ADDR_INCR,
   DISABLE_DELTA                       => DISABLE_DELTA
  )
  port map (
    Clk                                => clk,
    Addr                               => addr,
    BE                                 => be,
    WE                                 => wr,
    RD                                 => rd,
    DataOut                            => data_out,
    DataIn                             => data_in,
    WRAck                              => wrack,
    RDAck                              => rdack,
    Burst                              => burst,
    BurstFirst                         => burst_first,
    BurstLast                          => burst_last,
    Interrupt                          => irq,
    Update                             => update,
    UpdateResponse                     => update_response,
    Node                               => std_logic_vector(to_unsigned(NODE, NODE_WIDTH))
  );

else generate

  -- ---------------------------------------------------------
  -- Virtual Processor 64-bit
  -- ---------------------------------------------------------

  vp64 : entity work.VProc64
  generic map (
   INT_WIDTH                           => INT_WIDTH,
   NODE                                => NODE,
   BURST_ADDR_INCR                     => BURST_ADDR_INCR,
   DISABLE_DELTA                       => DISABLE_DELTA
  )
  port map (
    Clk                                => clk,
    Addr                               => addr,
    BE                                 => be,
    WE                                 => wr,
    RD                                 => rd,
    DataOut                            => data_out,
    DataIn                             => data_in,
    WRAck                              => wrack,
    RDAck                              => rdack,
    Burst                              => burst,
    BurstFirst                         => burst_first,
    BurstLast                          => burst_last,
    Interrupt                          => irq,
    Update                             => update,
    UpdateResponse                     => update_response
  );

end generate;

end behavioural;
