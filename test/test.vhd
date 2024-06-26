-- =============================================================
--
-- Top level demonstration test environment for VProc
--
-- Copyright (c) 2021 Simon Southwell. Confidential
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
-- $Id: test.vhd,v 1.1 2021/05/04 15:59:07 simon Exp $
-- $Source: /home/simon/CVS/src/HDL/VProc/test.vhd,v $
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

  signal  Interrupt0, Interrupt1       : std_logic_vector(2 downto 0)     := "000";
  signal  notReset_H                   : std_logic                        := '0';
  signal  UpdateResponse               : std_logic_vector(1 downto 0)     := "11";

  signal  VPAddr0, VPDataOut0          : std_logic_vector(31 downto 0)    := 32x"0";
  signal  VPAddr1, VPDataOut1          : std_logic_vector(31 downto 0)    := 32x"0";
  signal  VPDataIn0, VPDataIn1         : std_logic_vector(31 downto 0)    := 32x"0";
  signal  VPBE0, VPBE1                 : std_logic_vector(3 downto 0)     :=  4x"F";
  signal  VPWE0, VPWE1                 : std_logic;
  signal  VPRD0, VPRD1                 : std_logic;
  signal  Update                       : std_logic_vector(1 downto 0);
  signal  notReset                     : std_logic;
  signal  ResetInt                     : std_logic                        := '0';
  signal  CS1                          : std_logic;
  signal  Mem                          : array_t (0 to 1023)(31 downto 0) := (others => 32x"0");

begin

  ---------------------------------------------
  -- Combinatorial logic
  ---------------------------------------------
  notReset                             <= '1' when (Count > 5) else '0';
  CS1                                  <= '1' when VPAddr1(31 downto 28) = 4x"a" else '0';

  ---------------------------------------------
  -- VProc 0
  ---------------------------------------------

  vp0 : entity work.VProc
  port map (
    Clk                                => Clk,
    Addr                               => VPAddr0,
    BE                                 => VPBE0,
    WE                                 => VPWE0,
    RD                                 => VPRD0,
    DataOut                            => VPDataOut0,
    DataIn                             => VPDataIn0,
    WRAck                              => VPWE0,
    RDAck                              => VPRD0,
    Interrupt                          => ResetInt & Interrupt0(1 downto 0),
    Update                             => Update(0),
    UpdateResponse                     => UpdateResponse(0),
    Node                               => 4x"0"
  );

  ---------------------------------------------
  -- VProc 1
  ---------------------------------------------

  vp1 : entity work.VProc
  generic map (
    BURST_ADDR_INCR                    => 4
  )
  port map (
    Clk                                => Clk,
    Addr                               => VPAddr1,
    BE                                 => VPBE1,
    WE                                 => VPWE1,
    RD                                 => VPRD1,
    DataOut                            => VPDataOut1,
    DataIn                             => VPDataIn1,
    WRAck                              => VPWE1,
    RDAck                              => VPRD1,
    Interrupt                          => Interrupt1,
    Update                             => Update(1),
    UpdateResponse                     => UpdateResponse(1),
    Node                               => 4x"1"
  );

  ---------------------------------------------
  -- Response processes
  ---------------------------------------------

  P_UPDT0 : process(Update(0))
  begin
    UpdateResponse(0)                  <= not UpdateResponse(0);
  end process;

  P_UPDT1 : process(Update(1))
  begin
    UpdateResponse(1)                  <= not UpdateResponse(1);
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
    variable Seed1                     : natural := 16#250864#;
    variable Seed2                     : natural := 16#468025#;
    variable RandNumR                  : real;
    variable RandNumI0                 : natural;
    variable RandNumI1                 : natural;
  begin
    if Clk'event and Clk = '1' then

      ResetInt                         <= notReset and not notReset_H;

      if Count = StopCount then
        stop(0);
      end if;

      notReset_H                       <= notReset;

      Count                            <= Count + 1;

      uniform(Seed1, Seed2, RandNumR);
      RandNumI0                        := natural(65536.0 * RandNumR);

      uniform(Seed1, Seed2, RandNumR);
      RandNumI1                        := natural(65536.0 * RandNumR);

      VPDataIn0                        <= std_logic_vector(to_unsigned(RandNumI0, 16)) &
                                          std_logic_vector(to_unsigned(RandNumI1, 16)) ;

      uniform(Seed1, Seed2, RandNumR);
      RandNumI0                        := natural(16.0 * RandNumR);

      if count >= 32 and count < 42 then
        Interrupt1(1)                  <= '1';
      else
        Interrupt1(1)                  <= '0';
      end if;

      if RandNumI0 = 0 then
        Interrupt0(0)                  <= '1';
      else
        Interrupt0(0)                  <= '0';
      end if;

      uniform(Seed1, Seed2, RandNumR);
      RandNumI0                        := natural(16.0 * RandNumR);

      if RandNumI0 = 0 then
        Interrupt1(0)                  <= '1';
      else
        Interrupt1(0)                  <= '0';
      end if;

    end if;
  end process;

  ---------------------------------------------
  -- Memory model
  ---------------------------------------------

  P_MEM : process (Clk, VPAddr1)
  variable midx : integer;
  begin

    -- Read memory
    VPDataIn1                          <= Mem(to_integer(unsigned(VPAddr1(11 downto 2))));

    -- Write memory
    if Clk'event and Clk = '1' then
      if VPWE1 = '1' and CS1 = '1' then
        midx := to_integer(unsigned(VPAddr1(11 downto 2)));
        Mem(midx)(31 downto 24) <= VPDataOut1(31 downto 24) when VPBE1(3) else Mem(midx)(31 downto 24);
        Mem(midx)(23 downto 16) <= VPDataOut1(23 downto 16) when VPBE1(2) else Mem(midx)(23 downto 16);
        Mem(midx)(15 downto  8) <= VPDataOut1(15 downto  8) when VPBE1(1) else Mem(midx)(15 downto  8);
        Mem(midx)( 7 downto  0) <= VPDataOut1( 7 downto  0) when VPBE1(0) else Mem(midx)( 7 downto  0);
      end if;
    end if;

  end process;

end sim;

