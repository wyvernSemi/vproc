-- ====================================================================
--
-- VHDL APB bus functional model (BFM) wrapper for VProc.
--
-- Copyright (c) 2024 - 2025 Simon Southwell.
--
-- Implements minimal compliant initiator interface at 32-bits or
-- 64-bits wide. Also has a vectored irq input.
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

entity apbbfm is
generic (
    ADDRWIDTH                 : integer := 32;        -- For future proofing. Do not change.
    DATAWIDTH                 : integer := ADDRWIDTH; -- For future proofing. Do not change.
    IRQWIDTH                  : integer := 32;        -- Range 1 to 32
    REGDLY                    : time    := 1 ns;
    NODE                      : integer := 0
);
port (
    pclk                      : in std_logic;
    presetn                   : in std_logic;

    -- Master PSEL. Decode paddr externally for each individual completer
    pselx                     : out std_logic;

    paddr                     : out std_logic_vector (ADDRWIDTH-1 downto 0);
    pwdata                    : out std_logic_vector (DATAWIDTH-1 downto 0);
    pwrite                    : out std_logic;
    penable                   : out std_logic;

    pstrb                     : out std_logic_vector (DATAWIDTH/8-1 downto 0);
    pprot                     : out std_logic_vector (2 downto 0);

    prdata                    : in  std_logic_vector (DATAWIDTH-1 downto 0);
    pready                    : in  std_logic;
    pslverr                   : in  std_logic := '0';

    irq                       : in  std_logic_vector (IRQWIDTH-1 downto 0) := (others => '0')

);
end entity;

architecture bfm of apbbfm is

-- -----------------------------------------
-- Signals declarations for VProc
-- -----------------------------------------

signal update                 : std_logic;
signal rd                     : std_logic;
signal addr                   : std_logic_vector (ADDRWIDTH-1 downto 0);
signal we                     : std_logic;
signal be                     : std_logic_vector (DATAWIDTH/8-1 downto 0);
signal wrack                  : std_logic;
signal dataout                : std_logic_vector (DATAWIDTH-1 downto 0);

signal datain                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal rdack                  : std_logic;

signal data_phase             : std_logic;
signal updateresp             : std_logic := '0';

signal psel                   : std_logic;

begin

-- -----------------------------------------
-- Combinatorial logic
-- -----------------------------------------

-- Fixed protection status
pprot                         <= "010"; -- Normal, insecure and data access

-- Pass through write enable, byte enables, address and output data directly from VProc
pwrite                        <= we;
paddr                         <= addr;
pwdata                        <= dataout;
pstrb                         <= be;

-- Assert global PSEL when reading or writing. Add configurable delay
-- to ensure all other outputs are stable to prevent delta glitches (aesthetics only)
psel                          <= (rd or we);
pselx                         <= psel after REGDLY;

-- Assert PENABLE if ot selected or in data phase
penable                       <= not psel or data_phase;

-- Input data directly from PRDATA
datain                        <= prdata;

-- Acknowledge reads or writes when PREADY asserted
rdack                         <= rd and pready;
wrack                         <= we and pready;

-- -----------------------------------------
-- Synchronous process
-- -----------------------------------------

process(pclk, presetn)
begin
  if presetn = '0' then
    data_phase                <= '0';
  elsif pclk'event and pclk = '1' then
    -- Data phase is set on PSEL if no PREADY (address phase),
    -- and cleared again when PREADY asserted (data phase and data returned).
    data_phase                <= (data_phase or psel) and not (psel and pready) after REGDLY;
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

-- -----------------------------------------
--  VProc instantiation
-- -----------------------------------------

  g_VPROC_64: if ADDRWIDTH = 64 generate

    vp : entity work.VProc64
      generic map(
        NODE                    => NODE,
        BURST_ADDR_INCR         => 8,
        INT_WIDTH               => IRQWIDTH
      )
      port map (
        Clk                     => pclk,
  
        -- Bus
        Addr                    => addr,
        DataOut                 => dataout,
        WE                      => we,
        BE                      => be,
        WRAck                   => wrack,
        DataIn                  => datain,
        RD                      => rd,
        RDAck                   => rdack,
  
        -- Interrupts
        Interrupt               => irq,
  
        -- Delta cycle control
        Update                  => update,
        UpdateResponse          => updateresp
    );

  else generate
  
    vp : entity work.VProc
      generic map(
        BURST_ADDR_INCR         => 4,
        INT_WIDTH               => IRQWIDTH
      )
      port map (
        Clk                     => pclk,
  
        -- Bus
        Addr                    => addr,
        DataOut                 => dataout,
        WE                      => we,
        BE                      => be,
        WRAck                   => wrack,
        DataIn                  => datain,
        RD                      => rd,
        RDAck                   => rdack,
  
        -- Interrupts
        Interrupt               => irq,
  
        -- Delta cycle control
        Update                  => update,
        UpdateResponse          => updateresp,
  
        Node                    =>std_logic_vector(to_unsigned(NODE, 4))
    );
    
  end generate;

end bfm;