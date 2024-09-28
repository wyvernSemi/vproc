
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

-- ---------------------------------------------------------
-- ---------------------------------------------------------

entity testavm is
generic (
  CLKPERIOD : time    := 10 ns;
  STOPCOUNT : integer := 100
);
end entity;

architecture behavioural of testavm is

signal clk                      : std_logic := '1';
signal count                    : integer   := 0;
signal nreset                   : std_logic;

signal av_address               : std_logic_vector (31 downto 0);
signal av_byteenable            : std_logic_vector ( 3 downto 0);
signal av_write                 : std_logic;
signal av_writedata             : std_logic_vector (31 downto 0);
signal av_read                  : std_logic;
signal av_readdata              : std_logic_vector (31 downto 0);
signal av_readdatavalid         : std_logic;

signal irq                      : std_logic_vector (31 downto 0);

begin

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

process (clk)
begin
  if clk'event and clk = '1' then

    irq                         <= (others => '0');

    count                       <= count + 1;

    if count = STOPCOUNT then
      stop;
    end if;
  end if;
end process;

  avvp : entity work.avbfm
  generic map (NODE => 0)
  port map (
    clk                         => clk,

    av_address                  => av_address,
    av_byteenable               => av_byteenable,
    av_write                    => av_write,
    av_writedata                => av_writedata,
    av_read                     => av_read,
    av_readdata                 => av_readdata,
    av_readdatavalid            => av_readdatavalid,

    irq                         => irq
  );
  
  mem : entity work.mem_model
  port map (
  
    clk                         => clk,
    rst_n                       => nreset,
    
    address                     => av_address,
    byteenable                  => av_byteenable,
    write                       => av_write,
    writedata                   => av_writedata,
    read                        => av_read,
    readdata                    => av_readdata,
    readdatavalid               => av_readdatavalid,
    
    rx_waitrequest              => open,
    rx_burstcount               => (others => '0'),
    rx_address                  => (others => '0'),
    rx_read                     => '0',
    rx_readdata                 => open,
    rx_readdatavalid            => open,
    
    tx_waitrequest              => open,
    tx_burstcount               => (others => '0'),
    tx_address                  => (others => '0'),
    tx_write                    => '0',
    tx_writedata                => (others => '0'),

    wr_port_valid               => '0',
    wr_port_data                => (others => '0'),
    wr_port_addr                => (others => '0')

  );

end behavioural;


