-- =============================================================
--
--  Copyright (c) 2021-2023 Simon Southwell. All rights reserved.
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
-- =============================================================
-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vproc_pkg.all;

entity VProc is
  generic (INT_WIDTH       : integer := 3;
           NODE_WIDTH      : integer := 4;
           BURST_ADDR_INCR : integer := 1
  );
  port (
    Clk             : in  std_logic;

    Addr            : out std_logic_vector(31 downto 0) := 32x"0";
    WE              : out std_logic := '0';
    RD              : out std_logic := '0';
    DataOut         : out std_logic_vector(31 downto 0);
    DataIn          : in  std_logic_vector(31 downto 0);
    WRAck           : in  std_logic;
    RDAck           : in  std_logic;

    Interrupt       : in  std_logic_vector(INT_WIDTH-1 downto 0);

    Update          : out std_logic := '0';
    UpdateResponse  : in  std_logic;

    Burst           : out std_logic_vector(11 downto 0);
    BurstFirst      : out std_logic;
    BurstLast       : out std_logic;

    Node            : in  std_logic_vector(NODE_WIDTH-1 downto 0)
  );
end;

architecture model of VProc is

constant      WEbit       : integer := 0;
constant      RDbit       : integer := 1;
constant      BLKHIBIT    : integer := 13;
constant      BLKLOBIT    : integer := 2;
constant      DeltaCycle  : integer := -1;

signal        Initialised : integer := 0;

begin
  -- Initial
  pINIT : process
  begin
      -- Don't remove delay! Needed to allow Node to be assigned
      wait for 1 ns;

      VInit(to_integer(unsigned(Node)));

      Initialised               <= 1;

      wait;
  end process;


  -- Update process
  pUPDATE : process

    variable VPDataOut   : integer;
    variable VPAddr      : integer;
    variable VPRW        : integer;
    variable VPTicks     : integer;
    variable TickVal     : integer := 1;
    variable BlkCount    : integer := 0;
    variable AccIdx      : integer := 0;

    variable DataInSamp  : integer;
    variable IntSamp     : integer;
    variable IntSampLast : integer;
    variable RdAckSamp   : std_logic;
    variable WRAckSamp   : std_logic;

  begin

    while true loop

      -- Can't have a sensitivity list for the process and process delta cycles in VHDL,
      -- so emulate the clock edge with a wait here.
      wait until Clk'event and Clk = '1';

      -- Cleanly sample the inputs
      DataInSamp                := to_integer(signed(DataIn));
      IntSampLast               := IntSamp;
      IntSamp                   := to_integer(signed("0" & Interrupt));
      RdAckSamp                 := RDAck;
      WRAckSamp                 := WRAck;
      VPTicks                   := DeltaCycle;

      if Initialised = 1 then

        if IntSamp > 0 then

          -- If an interrupt active, call $vsched with interrupt value
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
            TickVal             := VPTicks;
          end if;
        end if;

        -- Call $virq when interrupt value changes, passing in
        -- new value
        if IntSamp /= IntSampLast then
          VIrq(to_integer(unsigned(Node)), IntSamp);
        end if;

        -- If tick, write or a read has completed (or in last cycle)...
        if  (RD = '0' and WE = '0' and TickVal = 0) or
            (RD = '1' and RdAckSamp = '1')          or
            (WE = '1' and WRAckSamp = '1') then

          BurstFirst            <= '0';
          BurstLast             <= '0';

          -- Loop accessing new commands until VPTicks is not a delta cycle update
          while VPTicks < 0 loop
            -- Clear any interrupt (already dealt with)
            IntSamp             := 0;

            -- Sample the data in port
            DataInSamp          := to_integer(signed(DataIn));

            if BlkCount <= 1 then

              -- If this is the last transfer in a burst, call $vaccess with
              -- the last data input sample.
              if BlkCount = 1 then
                AccIdx          := AccIdx + 1;

                VAccess(to_integer(unsigned(Node)),
                        AccIdx,
                        DataInSamp,
                        VPDataOut);
              end if;

              -- Host process message scheduler called
              VSched(to_integer(unsigned(Node)),
                     IntSamp,
                     DataInSamp,
                     VPDataOut,
                     VPAddr,
                     VPRW,
                     VPTicks);

              Burst             <= std_logic_vector(to_unsigned(VPRW, 14)(BLKHIBIT downto BLKLOBIT));
              WE                <= to_unsigned(VPRW, 14)(WEbit);
              RD                <= to_unsigned(VPRW, 14)(RDbit);
              Addr              <= std_logic_vector(to_signed(VPAddr, 32));

              BlkCount          := to_integer(to_unsigned(VPRW, 14)(BLKHIBIT downto BLKLOBIT));

              -- If new BlkCount is non-zero, setup burst transfer
              if BlkCount /= 0 then
                BurstFirst      <= '1';

                -- On writes, override VPDataOut to get from burst access task $VAccess at index 0
                if to_unsigned(VPRW, 14)(WEbit)  = '1' then
                  AccIdx        := 0;

                  VAccess(to_integer(unsigned(Node)),
                          AccIdx,
                          0,
                          VPDataOut);
                else
                  AccIdx        := -1;
                end if;
              end if;

              -- Update DataOut port
              DataOut           <= std_logic_vector(to_signed(VPDataOut, 32));

            -- If a block access is valid (BlkCount is non-zero), get the next data out/send back latest sample
            else
              AccIdx            := AccIdx + 1;

              VAccess(to_integer(unsigned(Node)),
                      AccIdx,
                      DataInSamp,
                      VPDataOut);

              DataOut           <= std_logic_vector(to_signed(VPDataOut, 32));
              Addr              <= std_logic_vector(unsigned(Addr) + BURST_ADDR_INCR);
              BlkCount          := BlkCount - 1;

              if BlkCount = 1 then
                  BurstLast     <= '1';
              end if;

              -- When bursting, reassert non-delta VPTicks value to break out of loop.
              VPTicks           := 0;

            end if;

            -- Update current tick value with returned number (if not zero)
            if VPTicks > 0 then
              TickVal           := VPTicks;
            end if;

            -- Flag to update externally and wait for response
            Update              <= not Update;
            wait on UpdateResponse;

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
