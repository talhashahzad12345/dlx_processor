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

signal tx_start : std_logic;
signal tx_data  : std_logic_vector(7 downto 0);
signal uart_tx_busy : std_logic;

type tx_ctrl_state_t is (IDLE, START_PULSE, WAIT_BUSY, WAIT_DONE);
signal tx_ctrl_state : tx_ctrl_state_t := IDLE;

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
    tx 		=> TX,
    busy    => uart_tx_busy
);

process(uart_clk)
begin
  if rising_edge(uart_clk) then

    -- defaults
    fifo_rd  <= '0';
    tx_start <= '0';

    case tx_ctrl_state is
      when IDLE =>
        if fifo_empty = '0' then
          fifo_rd <= '1';
          tx_data <= fifo_data_in;
          tx_start <= '1';
          tx_ctrl_state <= START_PULSE;
        end if;

      when START_PULSE =>
        tx_ctrl_state <= WAIT_BUSY;

      when WAIT_BUSY =>
        if uart_tx_busy = '1' then
          tx_ctrl_state <= WAIT_DONE;
        end if;

      when WAIT_DONE =>
        if uart_tx_busy = '0' then
          tx_ctrl_state <= IDLE;
        end if;
    end case;

  end if;
end process;

end rtl;
