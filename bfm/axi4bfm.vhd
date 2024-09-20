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
              BURST_ADDR_INCR     : integer :=  4;        -- Valid values => 1, 2, 4
              NODE                : integer :=  0
  );
  port (
    clk                           : in  std_logic;

    -- Write address channel
    awaddr                        : out std_logic_vector (ADDRWIDTH-1 downto 0);
    awvalid                       : out std_logic;
    awready                       : in  std_logic;
    awlen                         : out std_logic_vector (7 downto 0) ;
    awburst                       : out std_logic_vector (1 downto 0) := "01";
    awprot                        : out std_logic_vector (2 downto 0) := "000";

    -- Write Data channel
    wdata                         : out std_logic_vector (DATAWIDTH-1 downto 0);
    wvalid                        : out std_logic;
    wready                        : in  std_logic;
    wlast                         : out std_logic;
    wstrb                         : out std_logic_vector (DATAWIDTH/8-1 downto 0);

    -- Write response channel
    bvalid                        : in  std_logic;
    bready                        : out std_logic;

    -- Read address channel
    araddr                        : out std_logic_vector (ADDRWIDTH-1 downto 0);
    arvalid                       : out std_logic;
    arready                       : in  std_logic;
    arlen                         : out std_logic_vector (7 downto 0);
    arburst                       : out std_logic_vector (1 downto 0) := "01";
    arprot                        : out std_logic_vector (2 downto 0) := "000";

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
signal vpbyteenable               : std_logic_vector (3 downto 0);
signal vpburst                    : std_logic_vector (11 downto 0);
signal vpbursteq0                 : std_logic;
signal vplast                     : std_logic;
signal burstcount                 : unsigned (11 downto 0) := 12x"000";

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

-- Default signalling
bready                        <= bvalid;

-- The address/write data ports are only valid when their valid signals active,
-- else driven X. This ensures external IP does not use invalid held values.
awaddr                        <= vpaddr    when awvalid = '1' else (others => 'X');
araddr                        <= vpaddr    when arvalid = '1' else (others => 'X');

-- Burst
vpbursteq0                    <= '1' when vpburst = 12x"000" else '0';
awlen                         <= std_logic_vector(unsigned(vpburst(7 downto 0)) - 1) when vpbursteq0 = '0' else (others => '0');
arlen                         <= awlen;

wdata                         <= vpdataout when wvalid  = '1' else (others => 'X');

-- The write address and valid signals active when VProc writing,
-- but only until they have been acknowledged.
awvalid                       <= vpwe and not awacked;
wvalid                        <= vpwe and not wacked;

-- VProc write acknowledged only once both address and write channels have
-- been acknowledged. This could be if both channels acknowledged together,
-- if write address acknowledged first then write data, or write data acknowledged
-- first and then write address.
vpwrack                       <= (awready and wready) or (awacked and wready) or (awready and wacked);

-- Write Last always signalled when data valid as only one word at a time.
wlast                         <= wvalid and (vplast or vpbursteq0);

-- Export VProc's byte enables
wstrb                         <= vpbyteenable;

-- The read address is valid when VProc RD strobe active until it has
-- been acknowledged.
arvalid                       <= vprd and not aracked;

-- Read data always accepted.
rready                        <= rvalid;

-- The VProc read acknowlege comes straight from the AXI read data bus valid.
vprdack                       <= rvalid;

-- ---------------------------------------------------------
-- Synchronous process to generate state to indicate acknowledged
-- a channel has been acknowledged whilst the transaction is
-- incomplete.
-- ---------------------------------------------------------

process (clk)
  variable burst_cnt_leq_1 : std_logic;
begin
  if clk'event and clk = '1' then
  
    burst_cnt_leq_1           := '1' when to_integer(burstcount) <= 1 else '0'; 
  
    -- A channel is flagged as acknowledged if the VProc strobe active and the AXI
    -- ready signal is active. This state is held until The entire transaction
    -- is acknowledged back to VProc.

    -- Read address channel
    aracked                   <= (aracked or (vprd and arready)) and not (vprdack and burst_cnt_leq_1);

    -- Write address channel
    awacked                   <= (awacked or (vpwe and awready)) and not vpwrack;

    -- Write data channel
    wacked                    <= (wacked  or (vpwe and wready))  and not vpwrack;
    
    -- If a new burst count, set the counter to the burst length
    if arvalid = '1' and to_integer(burstcount) = 0 then
      burstcount              <= unsigned(vpburst);
    end if;
    
    -- If the counter is not zero, decrement the count when a word is received
    if burstcount > 0 and rvalid = '1' and rready = '1' then
      burstcount              <= burstcount - 1;
    end if;
    
  end if;

end process;

-- ---------------------------------------------------------
-- Delta cycle update process. Currently unused, but
-- functionality can be added here, such as upgrade
-- for wider bus architecture.
-- ---------------------------------------------------------

process (update)
begin
  updateresponse              <=  not updateresponse;
end process;

-- ---------------------------------------------------------
-- Virtual Processor
-- ---------------------------------------------------------

  vp : entity work.VProc
  generic map (
    INT_WIDTH                 => IRQWIDTH,
    BURST_ADDR_INCR           => BURST_ADDR_INCR
  )                           
  port map (                  
    Clk                       => clk,
                              
    Addr                      => vpaddr,
                              
    DataOut                   => vpdataout,
    WE                        => vpwe,
    WRAck                     => vpwrack,
                              
    BE                        => vpbyteenable,
                              
    DataIn                    => rdata,
    RD                        => vprd,
    RDAck                     => vprdack,
                              
    Burst                     => vpburst,     
    BurstFirst                => open,
    BurstLast                 => vplast,
                              
    Interrupt                 => irq,
                              
    Update                    => update,
    UpdateResponse            => updateresponse,
    Node                      => std_logic_vector(to_unsigned(NODE, 4))
  );

end bfm;