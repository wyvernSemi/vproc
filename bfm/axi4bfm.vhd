-- ====================================================================
--
-- VHDL AXI bus functional model (BFM) wrapper for VProc.
--
-- Copyright (c) 2024 Simon Southwell.
--
-- Implements minimal compliant manager interface at 32-bits wide.
-- Also has a 32-bit vectored irq input. Does not (yet) utilise
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

entity axi4bfm is
  generic    (ADDRWIDTH           : integer :=  32;       -- For future proofing. Do not change
              DATAWIDTH           : integer :=  32;       -- For future proofing. Do not change
              IRQWIDTH            : integer :=  32;       -- Valid ranges => 1 to 32
              BURST_ADDR_INCR     : integer :=  1;        -- Valid values => 1, 2, 4
              NODE                : integer :=  0
  );
  port (
    clk                           : in  std_logic;

    -- Write address channel
    awaddr                        : out std_logic_vector (ADDRWIDTH-1 downto 0);
    awvalid                       : out std_logic;
    awready                       : in  std_logic;
    awprot                        : out std_logic_vector (2 downto 0);

    -- Write Data channel
    wdata                         : out std_logic_vector (DATAWIDTH-1 downto 0);
    wvalid                        : out std_logic;
    wready                        : in  std_logic;
    wlast                         : out std_logic;

    -- Write response channel
    bvalid                        : in  std_logic;
    bready                        : out std_logic;

    -- Read address channel
    araddr                        : out std_logic_vector (ADDRWIDTH-1 downto 0);
    arvalid                       : out std_logic;
    arready                       : in  std_logic;
    arprot                        : out std_logic_vector (2 downto 0);

    -- Read data/response channel
    rdata                         : in  std_logic_vector (DATAWIDTH-1 downto 0);
    rvalid                        : in  std_logic;
    rready                        : out std_logic;

    -- Interrupt request (non-AXI side bus)
    irq                           : in std_logic_vector (IRQWIDTH-1 downto 0)
  );
end;

architecture bfm of axi4bfm is

-- ---------------------------------------------------------
-- Signal and register declarations
-- ---------------------------------------------------------

-- Virtual processor memory mapped address port signals
signal vpdataout                  : std_logic_vector (31 downto 0);
signal vpaddr                     : std_logic_vector (31 downto 0);
signal vpwe                       : std_logic;
signal vprd                       : std_logic;
signal vpwrack                    : std_logic;
signal vprdack                    : std_logic;

-- Delta cycle signals
signal update                     : std_logic;
signal updateresponse             : std_logic := '1';

-- Internal state to flag an AXI channel has been acknowleged,
-- but transaction is still pending
signal awacked                    : std_logic := '0';
signal wacked                     : std_logic := '0';
signal aracked                    : std_logic := '0';

begin

-- ---------------------------------------------------------
-- Combinatorial logic
-- ---------------------------------------------------------

-- Default signalling (no protection, and write response always acknowleged)
awprot                          <= "000";
arprot                          <= "000";
bready                          <= bvalid;

-- The address/write data ports are only valid when their valid signals active,
-- else driven X. This ensures external IP does not use invalid held values.
awaddr                          <= vpaddr    when awvalid = '1' else (others => 'X');
araddr                          <= vpaddr    when arvalid = '1' else (others => 'X');
wdata                           <= vpdataout when wvalid  = '1' else (others => 'X');

-- The write address and valid signals active when VProc writing,
-- but only until they have been acknowledged.
awvalid                         <= vpwe and not awacked;
wvalid                          <= vpwe and not wacked;

-- VProc write acknowledged only once both address and write channels have
-- been acknowledged. This could be if both channels acknowledged together,
-- if write address acknowledged first then write data, or write data acknowledged
-- first and then write address.
vpwrack                         <= (awready and wready) or (awacked and wready) or (awready and wacked);

-- Write Last always signalled when data valid as only one word at a time.
wlast                           <= wvalid;

-- The read address is valid when VProc RD strobe active until it has
-- been acknowledged.
arvalid                         <= vprd and not aracked;

-- Read data always accepted.
rready                          <= rvalid;

-- The VProc read acknowlege comes straight from the AXI read data bus valid.
vprdack                         <= rvalid;

-- ---------------------------------------------------------
-- Synchronous process to generate state to indicate acknowledged
-- a channel has been acknowledged whilst the transaction is
-- incomplete.
-- ---------------------------------------------------------

process (clk)
begin
  if clk'event and clk = '1' then
    -- A channel is flagged as acknowledged if the VProc strobe active and the AXI
    -- ready signal is active. This state is held until The entire transaction
    -- is acknowledged back to VProc.

    -- Read address channel
    aracked                     <= (aracked or (vprd and arready)) and not vprdack;

    -- Write address channel
    awacked                     <= (awacked or (vpwe and awready)) and not vpwrack;

    -- Write data channel
    wacked                      <= (wacked  or (vpwe and wready))  and not vpwrack;
  end if;

end process;

-- ---------------------------------------------------------
-- Delta cycle update process. Currently unused, but
-- functionality can be added here, such as upgrade
-- for wider bus architecture.
-- ---------------------------------------------------------

process (update)
begin
  updateresponse                <=  not updateresponse;
end process;

-- ---------------------------------------------------------
-- Virtual Processor
-- ---------------------------------------------------------

  vp : entity work.VProc
  generic map (
    INT_WIDTH         => IRQWIDTH,
    BURST_ADDR_INCR   => BURST_ADDR_INCR
  )
  port map    (
    Clk               => clk,

    Addr              => vpaddr,

    DataOut           => vpdataout,
    WE                => vpwe,
    WRAck             => vpwrack,

    DataIn            => rdata,
    RD                => vprd,
    RDAck             => vprdack,

    Interrupt         => irq,

    Update            => update,
    UpdateResponse    => updateresponse,
    Node              => std_logic_vector(to_unsigned(NODE, 4))
  );

end bfm;