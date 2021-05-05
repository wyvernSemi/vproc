-- =============================================================
--  
--  Copyright (c) 2021 Simon Southwell. All rights reserved.
-- 
--  Date: 4th May 2021
-- 
--  This file is part of the VProc package.
-- 
--  VProc is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
-- 
--  VProc is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
-- 
--  You should have received a copy of the GNU General Public License
--  along with VProc. If not, see <http://www.gnu.org/licenses/>.
-- 
--  $Id: f_vproc.vhd,v 1.2 2021/05/05 08:07:40 simon Exp $
--  $Source: /home/simon/CVS/src/HDL/VProc/f_vproc.vhd,v $
-- 
-- =============================================================
-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vproc_pkg.all;

entity VProc is
  port (
    Clk             : in  std_logic;
    Addr            : out std_logic_vector(31 downto 0) := 32x"0";
    WE              : out std_logic := '0';
    RD              : out std_logic := '0';
    DataOut         : out std_logic_vector(31 downto 0);
    DataIn          : in  std_logic_vector(31 downto 0);
    WRAck           : in  std_logic;
    RDAck           : in  std_logic;
    Interrupt       : in  std_logic_vector(2 downto 0);
    Update          : out std_logic := '0';
    UpdateResponse  : in  std_logic;
    Node            : in  std_logic_vector(3 downto 0)
  );
end;

architecture model of VProc is

constant      WEbit       : integer := 0;
constant      RDbit       : integer := 1;
constant      DeltaCycle  : integer := -1;

signal        Initialised : integer := 0;

begin
  -- Initial
  pINIT : process
  begin
      -- Don't remove delay! Needed to allow Node to be assigned
      wait for 1 ns;

      VInit(to_integer(unsigned(Node)));

      Initialised        <= 1;

      wait;
  end process;


  -- Update process
  pUPDATE : process

    variable VPDataOut   : integer;
    variable VPAddr      : integer;
    variable VPRW        : integer;
    variable VPTicks     : integer;
    variable TickVal     : integer := 1;

    variable DataInSamp  : integer;
    variable IntSamp     : integer;
    variable RdAckSamp   : std_logic;
    variable WRAckSamp   : std_logic;

  begin

    while true loop

      -- Can't have a sensitivity list for the process and process delta cyclies in VHDL,
      -- so emulate the clock edge with a wait here.
      wait until Clk'event and Clk = '1';

      -- Cleanly sample the inputs
      DataInSamp   := to_integer(signed(DataIn));
      IntSamp      := to_integer(signed("0" & Interrupt));
      RdAckSamp    := RDAck;
      WRAckSamp    := WRAck;

      if Initialised = 1 then

        if IntSamp > 0 then

          VSched(to_integer(unsigned(Node)),
                 IntSamp,
                 DataInSamp,
                 VPDataOut,
                 VPAddr,
                 VPRW,
                 VPTicks);

          -- If interrupt routine returns non-zero tick, then override
          -- current tick value. Otherwise, leave at present value.
          if VPTicks > 0 then
            TickVal      := VPTicks;
          end if;
        end if;

        -- If tick, write or a read has completed...
        if  (RD = '0' and WE = '0' and TickVal = 0) or
            (RD = '1' and RdAckSamp = '1')          or
            (WE = '1' and WRAckSamp = '1') then

          -- Host process message scheduler called
          VSched(to_integer(unsigned(Node)),
                 0,
                 DataInSamp,
                 VPDataOut,
                 VPAddr,
                 VPRW,
                 VPTicks);

          --wait for 0 ns;

          WE             <= to_unsigned(VPRW, 2)(WEbit);
          RD             <= to_unsigned(VPRW, 2)(RDbit);
          DataOut        <= std_logic_vector(to_signed(VPDataOut, 32));
          Addr           <= std_logic_vector(to_signed(VPAddr, 32));
          Update         <= not Update;

          wait on UpdateResponse;

          -- Update current tick value with returned number (if not zero)
          if VPTicks > 0 then
          
            TickVal      := VPTicks;
            
          elsif VPTicks < 0 then
          
            while VPTicks = DeltaCycle loop

              -- Resample delta input data
              DataInSamp := to_integer(signed(DataIn));

              VSched(to_integer(unsigned(Node)),
                     0,
                     DataInSamp,
                     VPDataOut,
                     VPAddr,
                     VPRW,
                     VPTicks);

              WE         <= to_unsigned(VPRW, 2)(WEbit);
              RD         <= to_unsigned(VPRW, 2)(RDbit);
              DataOut    <= std_logic_vector(to_signed(VPDataOut, 32));
              Addr       <= std_logic_vector(to_signed(VPAddr, 32));
              Update     <= not Update;

              if VPTicks >= 0 then
                TickVal  := VPTicks;
              end if;

              wait on UpdateResponse;

            end loop;
          end if;

        else
        
          -- Count down to zero and stop
          if TickVal > 0 then
            TickVal      := TickVal - 1;
          else
            TickVal      := 0;
          end if;
          
        end if;

      end if;
    end loop;
  end process;

end architecture;
