-- =============================================================
--
-- Top level test environment for VHDL APB BFM VProc wrapper
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
-- APB test bench
-- ---------------------------------------------------------

entity testapb is
generic (
  CLKPERIOD                   : time    := 10 ns;
  STOPCOUNT                   : integer := 200
);
end entity;

architecture behavioural of testapb is

constant ADDRWIDTH            : integer := 32;
constant DATAWIDTH            : integer := 32;

signal pselx                  : std_logic;

signal paddr                  : std_logic_vector (ADDRWIDTH-1 downto 0);
signal pwdata                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal pwrite                 : std_logic;
signal penable                : std_logic;

signal pstrb                  : std_logic_vector (DATAWIDTH/8-1 downto 0);
signal pprot                  : std_logic_vector (2 downto 0);

signal prdata                 : std_logic_vector (DATAWIDTH-1 downto 0);
signal pready                 : std_logic;
signal pslverr                : std_logic;

signal nreset                 : std_logic;

signal clk                    : std_logic := '1';
signal count                  : integer   := 0;
signal irq                    : std_logic_vector (31 downto 0);

begin

-- Generate a reset
nreset                        <= '1' when count >= 10 else  '0';

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

---------------------------------------------
-- Simulation control
---------------------------------------------

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

  vp : entity work.apbbfm
  generic map (
    NODE                      => 0
  )
  port map (
    pclk                      => clk,
    presetn                   => nreset,

    pselx                     => pselx,

    paddr                     => paddr,
    pwdata                    => pwdata,
    pwrite                    => pwrite,
    penable                   => penable,

    pstrb                     => pstrb,
    pprot                     => pprot,

    prdata                    => prdata,
    pready                    => pready,
    pslverr                   => pslverr,

    irq                       => irq
  );

-- -------------------------------------------
-- Instantiation of mem_model
-- -------------------------------------------

  mem : entity work.mem_model_apb
  port map (
    pclk                      => clk,
    presetn                   => nreset,

    psel                      => pselx,

    paddr                     => paddr,
    pwdata                    => pwdata,
    pwrite                    => pwrite,
    penable                   => penable,

    pstrb                     => pstrb,
    pprot                     => pprot,

    prdata                    => prdata,
    pready                    => pready,
    pslverr                   => pslverr
  );

end behavioural;


