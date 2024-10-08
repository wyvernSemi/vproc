-- =============================================================
--
-- Top level test environment for VHDL AHB BFM VProc wrapper
--
-- Copyright (c) 2024 Simon Southwell. Confidential
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
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

-- ---------------------------------------------------------
-- AHB test bench
-- ---------------------------------------------------------

entity testahb is
generic (
  CLKPERIOD                   : time    := 10 ns;
  STOPCOUNT                   : integer := 200
);
end entity;

architecture behavioural of testahb is

constant ADDRWIDTH            : integer  := 32;
constant DATAWIDTH            : integer  := 32;

signal hsel                   : std_logic;
signal haddr                  : std_logic_vector (ADDRWIDTH-1 downto 0);
signal hwdata                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal hwrite                 : std_logic;
signal hburst                 : std_logic_vector (2 downto 0);
signal hsize                  : std_logic_vector (2 downto 0);
signal htrans                 : std_logic_vector (1 downto 0);
signal hmastlock              : std_logic;
signal hwstrb                 : std_logic_vector (DATAWIDTH/8-1 downto 0);
signal hrdata                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal hready                 : std_logic;
signal hresp                  : std_logic;

signal nreset                 : std_logic;

signal clk                    : std_logic := '1';
signal count                  : integer := 0;
signal irq                    : std_logic_vector (31 downto 0) := (others => '0');

begin

-- -------------------------------------------
-- Combinatorial logic
-- -------------------------------------------

-- Genereate a reset
nreset                        <= '1' when count >= 10 else '0';

hsel                          <= '1';

-- -------------------------------------------
--  Clock generation
-- -------------------------------------------

  P_CLKGEN : process
  begin
    -- Generate a clock cycle
    loop
      clk                       <= '1';
      wait for CLKPERIOD/2;
      clk                       <= '0';
      wait for CLKPERIOD/2;
    end loop;
  end process;

-- -------------------------------------------
-- Synchronous process
-- -------------------------------------------

process (clk)
begin
  if clk'event and clk = '1' then

    count                       <= count + 1;

    if count = STOPCOUNT then
      stop;
    end if;
  end if;
end process;

-- -------------------------------------------
-- Instantiation of VProc
-- -------------------------------------------

  ahbvp : entity work.ahbbfm
  generic map (
    NODE                      => 0
  )
  port map (
    hclk                      => clk,
    hresetn                   => nreset,

    haddr                     => haddr,
    hwdata                    => hwdata,
    hwrite                    => hwrite,
    hburst                    => hburst,
    hsize                     => hsize,
    htrans                    => htrans,
    hmastlock                 => hmastlock,
    hwstrb                    => hwstrb,

    hrdata                    => hrdata,
    hready                    => hready,
    hresp                     => hresp,

    irq                       => irq
  );

-- -------------------------------------------
-- Instantiation of mem_model
-- -------------------------------------------

  mem : entity work.mem_model_ahb
  port map (
    hclk                     => clk,
    hresetn                  => nreset,

    hsel                     => hsel,
    haddr                    => haddr,
    hwdata                   => hwdata,
    hwrite                   => hwrite,
    hburst                   => hburst,
    hsize                    => hsize,
    htrans                   => htrans,
    hmastlock                => hmastlock,
    hwstrb                   => hwstrb,

    hrdata                   => hrdata,
    hready                   => hready,
    hresp                    => hresp
  );

end behavioural;


