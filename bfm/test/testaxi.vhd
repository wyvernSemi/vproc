-- =============================================================
--
-- Top level test environment for VHDL AXI BFM VProc wrapper
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

entity testaxi is
generic (
  CLKPERIOD : time    := 10 ns;
  STOPCOUNT : integer := 200
);
end entity;

architecture behavioural of testaxi is

signal clk                      : std_logic := '1';
signal count                    : integer   := 0;

signal awaddr                   : std_logic_vector (31 downto 0);
signal awvalid                  : std_logic;
signal awready                  : std_logic;
signal awlen                    : std_logic_vector  (7 downto 0);
signal awprot                   : std_logic_vector  (2 downto 0);

signal wdata                    : std_logic_vector (31 downto 0);
signal wvalid                   : std_logic;
signal wready                   : std_logic;
signal wstrb                    : std_logic_vector  (3 downto 0);
signal wlast                    : std_logic := '0';

signal bready                   : std_logic;
signal bvalid                   : std_logic;

signal araddr                   : std_logic_vector (31 downto 0);
signal arvalid                  : std_logic;
signal arready                  : std_logic;
signal arlen                    : std_logic_vector  (7 downto 0);
signal arprot                   : std_logic_vector  (2 downto 0);

signal rdata                    : std_logic_vector (31 downto 0);
signal rvalid                   : std_logic;
signal rready                   : std_logic;

signal irq                      : std_logic_vector (31 downto 0) := 32x"00000000";

signal nreset                   : std_logic;

begin

-- ---------------------------------------------------------
-- Combinatorial logic
-- ---------------------------------------------------------

nreset                          <= '1' when (count >= 10) else '0';

  ---------------------------------------------
  -- Clock generation
  ---------------------------------------------

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

  ---------------------------------------------
  -- AXI bus functional model
  ---------------------------------------------

  axivp : entity work.axi4bfm
  generic map (NODE => 0)
  port map (
    clk                         => clk,

    awaddr                      => awaddr,
    awvalid                     => awvalid,
    awready                     => awready,
    awlen                       => awlen,
    awprot                      => awprot,

    wdata                       => wdata,
    wvalid                      => wvalid,
    wready                      => wready,
    wstrb                       => wstrb,
    wlast                       => wlast,

    bvalid                      => bvalid,
    bready                      => bready,

    araddr                      => araddr,
    arvalid                     => arvalid,
    arready                     => arready,
    arlen                       => arlen,
    arprot                      => arprot,

    rdata                       => rdata,
    rvalid                      => rvalid,
    rready                      => rready,

    irq                         => irq
  );

-- ---------------------------------------------------------
-- Memory model
-- ---------------------------------------------------------

  mem : entity work.mem_model_axi
  port map (
    clk                         => clk,
    nreset                      => nreset,

    awaddr                      => awaddr,
    awvalid                     => awvalid,
    awready                     => awready,
    awlen                       => awlen,

    wdata                       => wdata,
    wvalid                      => wvalid,
    wready                      => wready,
    wstrb                       => wstrb,

    bvalid                      => bvalid,
    bready                      => bready,

    araddr                      => araddr,
    arvalid                     => arvalid,
    arready                     => arready,
    arlen                       => arlen,

    rdata                       => rdata,
    rvalid                      => rvalid,
    rready                      => rready
  );

end behavioural;
