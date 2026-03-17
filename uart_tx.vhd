library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
port(
    clk : in std_logic;
    start : in std_logic;
    data_in : in std_logic_vector(7 downto 0);
    tx : out std_logic
);
end uart_tx;

architecture rtl of uart_tx is

type state_type is (IDLE, START_BIT, DATA, STOP);

signal state : state_type := IDLE;
signal bit_index : integer range 0 to 7 := 0;
signal counter : integer range 0 to 7 := 0;

signal shift_reg : std_logic_vector(7 downto 0);

begin

process(clk)
begin
if rising_edge(clk) then

case state is

when IDLE =>
    tx <= '1';

    if start = '1' then
        shift_reg <= data_in;
        counter <= 0;
        state <= START_BIT;
    end if;

when START_BIT =>
    tx <= '0';

    if counter = 7 then
        counter <= 0;
        bit_index <= 0;
        state <= DATA;
    else
        counter <= counter + 1;
    end if;

when DATA =>
    tx <= shift_reg(bit_index);

    if counter = 7 then
        counter <= 0;

        if bit_index = 7 then
            state <= STOP;
        else
            bit_index <= bit_index + 1;
        end if;

    else
        counter <= counter + 1;
    end if;

when STOP =>
    tx <= '1';

    if counter = 7 then
        state <= IDLE;
    else
        counter <= counter + 1;
    end if;

end case;

end if;
end process;

end rtl;