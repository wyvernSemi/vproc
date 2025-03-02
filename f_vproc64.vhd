-- =============================================================
--
--  Copyright (c) 2025 Simon Southwell. All rights reserved.
--
--  Date: 3rd February 2025
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
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vproc64_pkg.all;

entity VProc64 is
  generic (
    NODE            : integer                              := 0;
    INT_WIDTH       : integer range 1 to 32                := 32;
    BURST_ADDR_INCR : integer range 1 to 8                 := 1;
    DISABLE_DELTA   : integer range 0 to 1                 := 0
  );
  port (
    Clk             : in  std_logic;

    Addr            : out std_logic_vector(63 downto 0)    := 64x"0";
    BE              : out std_logic_vector( 7 downto 0)    := 8x"FF";
    WE              : out std_logic                        := '0';
    RD              : out std_logic                        := '0';
    DataOut         : out std_logic_vector(63 downto 0);
    DataIn          : in  std_logic_vector(63 downto 0);
    WRAck           : in  std_logic                        := '0';
    RDAck           : in  std_logic                        := '0';

    Interrupt       : in  std_logic_vector(INT_WIDTH-1 downto 0) := (others => '0');

    Update          : out std_logic                        := '0';
    UpdateResponse  : in  std_logic                        := '0';

    Burst           : out std_logic_vector(11 downto 0)    := 12x"000";
    BurstFirst      : out std_logic                        := '0';
    BurstLast       : out std_logic                        := '0'
  );
end;

architecture model of VProc64 is

constant      WEbit        : integer := 0;
constant      RDbit        : integer := 1;
constant      BLKHIBIT     : integer := 13;
constant      BLKLOBIT     : integer := 2;
constant      BEFIRSTLOBIT : integer := 14;
constant      BEFIRSTHIBIT : integer := 21;
constant      BELASTLOBIT  : integer := 22;
constant      BELASTHIBIT  : integer := 29;
constant      DeltaCycle   : integer := -1;

signal        Initialised  : integer := 0;
signal        LBE          : std_logic_vector(7 downto 0)  := 8x"FF";

begin
  -- Initial
  pINIT : process
  begin

      VInit(NODE);

      Initialised               <= 1;

      wait;
  end process;

  -- Update process
  pUPDATE : process

    variable VPDataOutLo  : integer;
    variable VPDataOutHi  : integer;
    variable VPAddrLo     : integer;
    variable VPAddrHi     : integer;
    variable VPRW         : integer;
    variable VPTicks      : integer;
    variable TickVal      : integer := 1;
    variable BlkCount     : integer := 0;
    variable AccIdx       : integer := 0;

    variable DataInSampLo : integer;
    variable DataInSampHi : integer;
    variable IntSamp      : integer;
    variable IntSampLast  : integer := 0;
    variable RdAckSamp    : std_logic;
    variable WRAckSamp    : std_logic;

  begin

    while true loop

      -- Can't have a sensitivity list for the process and process delta cycles in VHDL,
      -- so emulate the clock edge with a wait here.
      wait until Clk'event and Clk = '1';

      -- Cleanly sample the inputs
      DataInSampLo              := to_integer(signed(DataIn(31 downto 0)));
      DataInSampHi              := to_integer(signed(DataIn(63 downto 32)));
      IntSamp                   := to_integer(signed(Interrupt));
      RdAckSamp                 := RDAck;
      WRAckSamp                 := WRAck;
      VPTicks                   := DeltaCycle;

      if Initialised = 1 then

        -- Call $virq when interrupt value changes, passing in
        -- new value
        if IntSamp /= IntSampLast then
          VIrq(NODE, IntSamp);
          IntSampLast := IntSamp;
        end if;

        -- If tick, write or a read has completed (or in last cycle)...
        if  (RD = '0' and WE = '0' and TickVal = 0) or
            (RD = '1' and RdAckSamp = '1')          or
            (WE = '1' and WRAckSamp = '1') then

          BurstFirst            <= '0';
          BurstLast             <= '0';

          -- Loop accessing new commands until VPTicks is not a delta cycle update
          while VPTicks < 0 loop

            -- Sample the data in port
            DataInSampLo        := to_integer(signed(DataIn(31 downto 0)));
            DataInSampHi        := to_integer(signed(DataIn(63 downto 32)));

            if BlkCount <= 1 then

              -- If this is the last transfer in a burst, call $vaccess with
              -- the last data input sample.
              if BlkCount = 1 then
              
                BlkCount        := 0; 
                
                if RD = '1' then
                    AccIdx          := AccIdx + 1;
                    VAccess(NODE, AccIdx*2,   DataInSampLo, VPDataOutLo);
                    VAccess(NODE, AccIdx*2+1, DataInSampHi, VPDataOutHi);
                end if;
              end if;

              -- Host process message scheduler called
              VSched64(NODE,
                       DataInSampLo, DataInSampHi,
                       VPDataOutLo,  VPDataOutHi,
                       VPAddrLo,     VPAddrHi,
                       VPRW,
                       VPTicks);

              Burst             <= std_logic_vector(to_unsigned(VPRW, 32)(BLKHIBIT     downto BLKLOBIT));
              BE                <= std_logic_vector(to_unsigned(VPRW, 32)(BEFIRSTHIBIT downto BEFIRSTLOBIT));
              LBE               <= std_logic_vector(to_unsigned(VPRW, 32)(BELASTHIBIT  downto BELASTLOBIT));
              WE                <= to_unsigned(VPRW, 32)(WEbit);
              RD                <= to_unsigned(VPRW, 32)(RDbit);
              Addr              <= std_logic_vector(to_signed(VPAddrHi, 32)) & std_logic_vector(to_signed(VPAddrLo, 32));

              BlkCount          := to_integer(to_unsigned(VPRW, 32)(BLKHIBIT downto BLKLOBIT));

              -- If new BlkCount is non-zero, setup burst transfer
              if BlkCount /= 0 then
                BurstFirst      <= '1';

                -- If a single word transfer, set the last flag
                if BlkCount = 1 then
                  BurstLast      <= '1';
                end if;

                -- On writes, override VPDataOut to get from burst access task $VAccess at index 0
                if to_unsigned(VPRW, 32)(WEbit)  = '1' then
                  AccIdx        := 0;

                  VAccess(NODE, AccIdx*2,   0, VPDataOutLo);
                  VAccess(NODE, AccIdx*2+1, 0, VPDataOutHi);
                else
                  AccIdx        := -1;
                end if;
              end if;

              -- Update DataOut port
              DataOut           <= std_logic_vector(to_signed(VPDataOutHi, 32)) & std_logic_vector(to_signed(VPDataOutLo, 32));

            -- If a block access is valid (BlkCount is non-zero), get the next data out/send back latest sample
            else
              AccIdx            := AccIdx + 1;

              VAccess(NODE, AccIdx*2,   DataInSampLo, VPDataOutLo);
              VAccess(NODE, AccIdx*2+1, DataInSampHi, VPDataOutHi);

              DataOut           <= std_logic_vector(to_signed(VPDataOutHi, 32)) & std_logic_vector(to_signed(VPDataOutLo, 32));
              Addr              <= std_logic_vector(unsigned(Addr) + BURST_ADDR_INCR);
              BlkCount          := BlkCount - 1;

              if BlkCount = 1 then
                  BurstLast     <= '1';
                  BE            <= LBE;
              else
                  BE            <= x"FF";
              end if;

              -- When bursting, reassert non-delta VPTicks value to break out of loop.
              VPTicks           := 0;

            end if;

            -- Update current tick value with returned number (if not zero)
            if VPTicks > 0 then
              TickVal           := VPTicks - 1;
            end if;

            -- Flag to update externally and wait for response
            Update              <= not Update;
            if DISABLE_DELTA = 0 then
              wait on UpdateResponse;
            end if;

          end loop;

        else

          -- Count down to zero and stop
          if TickVal > 0 then
            TickVal             := TickVal - 1;
          else
            TickVal             := 0;
          end if;

        end if;
      end if;
    end loop;
  end process;

end architecture;
