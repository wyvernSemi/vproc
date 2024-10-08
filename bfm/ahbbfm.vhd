-- ====================================================================
--
-- VHDL AHB bus functional model (BFM) wrapper for VProc.
--
-- Copyright (c) 2024 Simon Southwell.
--
-- Implements minimal compliant manager interface at 32-bits wide.
-- Also has a vectored irq input.
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

use work.ahbbfm_pkg.all;

entity ahbbfm is
generic (
    ADDRWIDTH                 : integer := 32; -- For future proofing. Do not change.
    DATAWIDTH                 : integer := 32; -- For future proofing. Do not change.
    IRQWIDTH                  : integer := 32; -- Range 1 to 32
    NODE                      : integer := 0   -- range 0 to 15
);
port (
    hclk                      : in  std_logic;
    hresetn                   : in  std_logic;

    haddr                     : out std_logic_vector (ADDRWIDTH-1 downto 0);
    hwdata                    : out std_logic_vector (DATAWIDTH-1 downto 0);
    hwstrb                    : out std_logic_vector (DATAWIDTH/8-1 downto 0);
    hwrite                    : out std_logic;
    hburst                    : out std_logic_vector (2 downto 0);
    hsize                     : out std_logic_vector (2 downto 0);
    htrans                    : out std_logic_vector (1 downto 0);
    hmastlock                 : out std_logic := '0';

    hrdata                    : in std_logic_vector (DATAWIDTH-1 downto 0);
    hready                    : in std_logic;
    hresp                     : in std_logic;

    irq                       : in std_logic_vector (IRQWIDTH-1 downto 0) := (others => '0')
);
end entity;

architecture bfm of ahbbfm is

-- Signals declarations for VProc

signal update                 : std_logic;
signal rd                     : std_logic;
signal addr                   : std_logic_vector (ADDRWIDTH-1 downto 0);
signal we                     : std_logic;
signal be                     : std_logic_vector (DATAWIDTH/8-1 downto 0);
signal wrack                  : std_logic;
signal dataout                : std_logic_vector (DATAWIDTH-1 downto 0);
signal burst                  : std_logic_vector (11 downto 0);
signal burstlast              : std_logic;
signal burstfirst             : std_logic;
signal burstactive            : std_logic;

signal datain                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal rdack                  : std_logic;

signal wdata_phase            : std_logic_vector (DATAWIDTH-1 downto 0);
signal rd_active              : std_logic := '0';
signal burstaddr              : std_logic_vector (ADDRWIDTH-1 downto 0);
signal burst_not_zero         : std_logic;
signal htrans_not_idle        : std_logic;
signal htrans_not_nonseq      : std_logic;
signal addrmux                : std_logic_vector (ADDRWIDTH-1 downto 0);

signal updateresp             : std_logic := '1';

begin

-- -----------------------------------------
-- Combinatorial logic
-- -----------------------------------------

-- Fixed signalling
hmastlock                     <= '0';
hsize                         <= AHB_BFM_SIZE_WORD;

-- HBurst set to INCR when bursting, else SINGLE
burst_not_zero                <= '1' when to_integer(unsigned(burst)) /= 0 else '0';
hburst                        <= AHB_BFM_BURST_INCR when burst_not_zero else AHB_BFM_BURST_SINGLE;
hwrite                        <= we;

-- HADDR, when not IDLE, is either straight from VProc addr output or,
-- for read bursts, switches to the aligned burstaddr after the first command.
-- When IDLE, make X.
addrmux                       <= addr when rd_active = '0' else burstaddr;
haddr                         <= addrmux when (htrans /= AHB_BFM_TRANS_IDLE) else (others => 'X');

-- HWDATA is the phase aligned data from VProc
hwdata                        <= wdata_phase;

-- Write strobe is direct from VProc when writing, else force to X
hwstrb                        <= be when hwrite = '1' else (others => 'X');

-- VProc data input is straight from HRDATA
datain                        <= hrdata;

-- Write acknowledge whe writing and HREADY
wrack                         <= we and hready;

-- Acknowledge read when reading, HREADY and either not the first command or bursting and data is returned.
htrans_not_idle               <= '1' when htrans /= AHB_BFM_TRANS_IDLE   else '0';
htrans_not_nonseq             <= '1' when htrans /= AHB_BFM_TRANS_NONSEQ else '0';
rdack                         <= rd and hready and (htrans_not_nonseq or (burst_not_zero and rd_active));

-- Process for HTRANS
process (all)
begin
    -- Default HTRANS to idle.
    htrans                    <= AHB_BFM_TRANS_IDLE;

    -- If writing, first command is a NONSEQ (not bursting or first burst),
    -- and subsequent commands in a burst are SEQ
    if we then

      if burst_not_zero = '0' or burstfirst = '1' then
        htrans                <= AHB_BFM_TRANS_NONSEQ;
      elsif burstfirst = '0' then
        htrans                <= AHB_BFM_TRANS_SEQ;
      end if;
    end if;

    -- If reading, first command is a NONSEQ (rd_active clear) else
    -- subsequent burst commands are SEQ
    if rd = '1' then
      if rd_active = '0' then
        htrans                <= AHB_BFM_TRANS_NONSEQ;
      elsif burst_not_zero = '1' and burstlast = '0' then
        htrans                <= AHB_BFM_TRANS_SEQ;
      end if;
    end if;
end process;

-- ---------------------------------------
-- Synchronous process
-- ---------------------------------------

process (hclk, hresetn)
begin
  if hresetn = '0' then
    rd_active                 <= '0';
  elsif hclk'event and hclk = '1' then

    -- Whilst writing, offset the output data by a cycle, else make X
    if we = '1' and hready = '1' then
      wdata_phase             <= dataout;
    else
      wdata_phase             <= (others => 'X');
    end if;

    -- A read is active after a non idle read is ouput, and cleared on the VProc read acknowledge
    -- when not a burst or on a read acknowledge when last data of a burst.
    rd_active                 <= (rd_active and not (rdack and (not burst_not_zero or burstlast))) or (not hwrite and htrans_not_idle);

    -- If reading, latch haddr + 4 on the first cycle, and then increment by 4, to align
    -- the address to AHB protocols (VProc will hold the first address until the data is returned).
    if rd = '1' then
      if rd_active = '0' then
        burstaddr             <= std_logic_vector(unsigned(haddr) + 4);
      else
        if hready = '1' then
          burstaddr           <= std_logic_vector(unsigned(burstaddr) + 4);
        end if;
      end if;
    end if;

  end if;

end process;

-- -----------------------------------------
-- Delta cycle process
-- -----------------------------------------

process(update)
begin
  -- Place any delta cycle processing logic before next line
  updateresp                  <= not updateresp;
end process;

-- ---------------------------------------
--  VProc instantiation
-- ---------------------------------------

    vp : entity work.VProc
    generic map (
      BURST_ADDR_INCR         => 4,
      INT_WIDTH               => IRQWIDTH
    )
    port map (
      Clk                     => hclk,

      -- Bus
      Addr                    => addr,
      DataOut                 => dataout,
      BE                      => be,
      WE                      => we,
      WRAck                   => wrack,
      DataIn                  => datain,
      RD                      => rd,
      RDAck                   => rdack,

      Burst                   => burst,
      BurstFirst              => burstfirst,
      BurstLast               => burstlast,

      -- Interrupts
      Interrupt               => irq,

      -- Delta cycle control
      Update                  => update,
      UpdateResponse          => updateresp,

      Node                    => std_logic_vector(to_unsigned(NODE, 4))
  );

end bfm;