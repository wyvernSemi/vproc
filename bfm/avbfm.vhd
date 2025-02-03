-- ====================================================================
--
-- VHDL Avalon bus functional model (BFM) wrapper for VProc.
--
-- Copyright (c) 2024 - 2025 Simon Southwell.
--
-- Implements minimal compliant manager interface at 32-bits or
-- 64-bits wide. Also has a vectored irq input. Does not (yet) utilise
-- VProc's burst capabilities.
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

entity avbfm is
  generic (
    ADDRWIDTH              : integer range 32 to 64 := 32;        -- For future proofing. Do not change.
    DATAWIDTH              : integer range 32 to 64 := ADDRWIDTH; -- For future proofing. Do not change.
    IRQWIDTH               : integer range 1  to 32 := 32;        -- Range 1 to 32
    NODE                   : integer range 0  to 15 := 0
  );
  port (
    clk                    : in  std_logic;

    -- Avalon memory mapped master interface
    av_address             : out std_logic_vector (ADDRWIDTH-1 downto 0);
    av_byteenable          : out std_logic_vector (DATAWIDTH/8-1 downto 0);
    av_write               : out std_logic;
    av_writedata           : out std_logic_vector (DATAWIDTH-1 downto 0);
    av_read                : out std_logic;
    av_readdata            : in  std_logic_vector (DATAWIDTH-1 downto 0) := (others => '0');
    av_readdatavalid       : in  std_logic                               := '0';

    -- Interrupt
    irq                    : in  std_logic_vector (IRQWIDTH-1 downto 0)  := (others => '0')
  );
end entity;

architecture bfm of avbfm is

  -- Signals for VProc
  signal update            : std_logic;
  signal updateresp        : std_logic := '0';
  signal rd                : std_logic;
  signal rdlast            : std_logic;
  signal addr              : std_logic_vector(ADDRWIDTH-1 downto 0);
  signal be                : std_logic_vector(DATAWIDTH/8-1 downto 0);
  signal we                : std_logic;
  signal dataout           : std_logic_vector(DATAWIDTH-1 downto 0);
  signal datain            : std_logic_vector(DATAWIDTH-1 downto 0);
  signal rdack             : std_logic;

begin
  -----------------------------------------
  -- Combinatorial logic
  -----------------------------------------

  -- Pulse the Avalon read signal only for the first cycle of rd, which won't be
  -- deasserted until av_readdatavalid is asserted.
  av_read                  <= rd and not rdlast;
  av_write                 <= we;
  av_writedata             <= dataout;
  av_address               <= addr;
  av_byteenable            <= be;

  datain                   <= av_readdata;
  rdack                    <= av_readdatavalid;

  -- Delta cycle process
  process (update)
  begin
    -- Place any delta cycle processing logic before next line
    updateresp             <= not updateresp;
  end process;

  -----------------------------------------
  -- Synchronous logic
  -----------------------------------------
  process(clk)
  begin
    if clk'event and clk = '1' then
      -- VProc's rd strobe delayed by a cycle
      rdlast               <= rd and not rdack;
    end if;
  end process;

  -----------------------------------------
  -- VProc instantiation
  -----------------------------------------

  g_VPROC_64: if ADDRWIDTH = 64 generate

    vp : entity work.VProc64
      generic map (
        NODE                 => NODE,
        INT_WIDTH            => IRQWIDTH
      )
      port map (
        Clk                  => clk,
    
        -- Bus
        Addr                 => addr,
        BE                   => be,
        DataOut              => dataout,
        WE                   => we,
        WRAck                => we,
        DataIn               => datain,
        RD                   => rd,
        RDAck                => rdack,
    
        -- Interrupts
        Interrupt            => irq,
        
        -- Delta cycle control
        Update               => update,
        UpdateResponse       => updateresp
      );

  else generate

    vp : entity work.VProc
      generic map (
        INT_WIDTH            => IRQWIDTH
      )
      port map (
        Clk                  => clk,
    
        -- Bus
        Addr                 => addr,
        BE                   => be,
        DataOut              => dataout,
        WE                   => we,
        WRAck                => we,
        DataIn               => datain,
        RD                   => rd,
        RDAck                => rdack,
    
        -- Interrupts
        Interrupt            => irq,
        
        -- Delta cycle control
        Update               => update,
        UpdateResponse       => updateresp,
    
        Node                 => std_logic_vector(to_unsigned(NODE, 4))
      );
  end generate;
  
end bfm;
