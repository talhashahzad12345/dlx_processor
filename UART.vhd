library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART is
port(
    CLOCK_50 : in std_logic;
    RX       : in std_logic;
    TX       : out std_logic;
    
    -- NEW FIFO INTERFACE
    fifo_data_in : in std_logic_vector(7 downto 0);
    fifo_empty   : in std_logic;
    fifo_rd      : out std_logic
);
end UART;

architecture rtl of UART is

signal uart_clk : std_logic;
signal rx_data  : std_logic_vector(7 downto 0);
signal rx_done  : std_logic;

signal tx_busy  : std_logic := '0';
signal tx_start : std_logic;
signal tx_data  : std_logic_vector(7 downto 0);

begin

-- PLL instance
pll_inst : entity work.pll
port map(
    inclk0 => CLOCK_50,
    c0     => uart_clk,
    locked => open
);

-- UART receiver
uart_rx_inst : entity work.uart_rx
port map(
    clk 			=> uart_clk,
    rx  			=> RX,
    data_out 	=> rx_data,
    done 		=> rx_done
);

-- UART transmitter
uart_tx_inst : entity work.uart_tx
port map(
    clk 		=> uart_clk,
    start 	=> tx_start,
    data_in => tx_data,
    tx 		=> TX
);

process(uart_clk)
begin
  if rising_edge(uart_clk) then

    -- defaults
    fifo_rd  <= '0';
    tx_start <= '0';

    if tx_busy = '0' then

      if fifo_empty = '0' then
        -- read from FIFO
        fifo_rd <= '1';
        tx_data <= fifo_data_in;
        tx_start <= '1';
        tx_busy <= '1';
      end if;

    else
      -- wait 1 cycle (tx_start pulse)
      tx_busy <= '0';
    end if;

  end if;
end process;

end rtl;