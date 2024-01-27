-- =============================================================
--
-- Top level demonstration test environment for Python VProc
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
use ieee.math_real.all;

library std;
use std.env.all;

entity test is
end entity;

architecture sim of test is

  ---------------------------------------------
  -- Declarations
  ---------------------------------------------

  type     array_t is array (natural range <>) of std_logic_vector;

  constant FREQ                        : real := 100.0e6;
  constant ClkPeriod                   : time := 1 sec / FREQ;
  constant StopCount                   : integer := 100;

  signal  Clk                          : std_logic                        := '1';
  signal  Count                        : integer                          := 0;

  signal  notReset_H                   : std_logic                        := '0';
  signal  UpdateResponse               : std_logic                        := '1';

  signal  VPAddr , VPDataOut           : std_logic_vector(31 downto 0)    := 32x"0";
  signal  VPDataIn                     : std_logic_vector(31 downto 0)    := 32x"0";
  signal  VPWE                         : std_logic;
  signal  VPRD                         : std_logic;
  signal  Update                       : std_logic;
  signal  notReset                     : std_logic;
  signal  CS1                          : std_logic;
  signal  Mem                          : array_t (0 to 1023)(31 downto 0) := (others => 32x"0");

begin

  ---------------------------------------------
  -- Combinatorial logic
  ---------------------------------------------
  notReset                             <= '1' when (Count > 5) else '0';
  CS1                                  <= '1' when VPAddr(31 downto 28) = 4x"a" else '0';

  ---------------------------------------------
  -- VProc 0
  ---------------------------------------------

  vp0 : entity work.VProc
  port map (
    Clk                                => Clk,
    Addr                               => VPAddr,
    WE                                 => VPWE,
    RD                                 => VPRD,
    DataOut                            => VPDataOut,
    DataIn                             => VPDataIn,
    WRAck                              => VPWE,
    RDAck                              => VPRD,
    Interrupt                          => 2x"0" & notReset,
    Update                             => Update,
    UpdateResponse                     => UpdateResponse,
    Node                               => 4x"0"
  );

  ---------------------------------------------
  -- Response process
  ---------------------------------------------

  P_UPDT : process(Update)
  begin
    -- USER CODE HERE --
    UpdateResponse                     <= not UpdateResponse;
  end process;

  ---------------------------------------------
  -- Clock generation
  ---------------------------------------------

  P_CLKGEN : process
  begin
    -- Generate a clock cycle
    loop
      Clk                              <= '1';
      wait for ClkPeriod/2.0;
      Clk                              <= '0';
      wait for ClkPeriod/2.0;
    end loop;
  end process;

  ---------------------------------------------
  -- Data generation
  ---------------------------------------------

  P_GENDATA : process (Clk)
  begin
    if Clk'event and Clk = '1' then

      if Count = StopCount then
        stop(0);
      end if;

      Count                            <= Count + 1;

    end if;
  end process;

  ---------------------------------------------
  -- Memory model
  ---------------------------------------------

  P_MEM : process (Clk, VPAddr)
  begin

    -- Read memory
    VPDataIn                           <= Mem(to_integer(unsigned(VPAddr(9 downto 0))));

    -- Write memory
    if Clk'event and Clk = '1' then
      if VPWE = '1' and CS1 = '1' then
        Mem(to_integer(unsigned(VPAddr(9 downto 0)))) <= VPDataOut;
      end if;
    end if;

  end process;

end sim;

