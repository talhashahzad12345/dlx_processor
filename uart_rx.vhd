library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
port(
    clk : in std_logic;
    rx  : in std_logic;
    data_out : out std_logic_vector(7 downto 0);
    done : out std_logic
);
end uart_rx;

architecture rtl of uart_rx is

type state_type is (IDLE, START, DATA, STOP);

signal state : state_type := IDLE;
signal sample_count : integer range 0 to 7 := 0;
signal bit_index : integer range 0 to 7 := 0;

signal shift_reg : std_logic_vector(7 downto 0);

begin

process(clk)
begin
if rising_edge(clk) then

case state is

when IDLE =>
    done <= '0';
    if rx = '0' then
        sample_count <= 0;
        state <= START;
    end if;

when START =>
    if sample_count = 3 then
        sample_count <= 0;
        bit_index <= 0;
        state <= DATA;
    else
        sample_count <= sample_count + 1;
    end if;

when DATA =>
    if sample_count = 7 then

        shift_reg(bit_index) <= rx;
        sample_count <= 0;

        if bit_index = 7 then
            state <= STOP;
        else
            bit_index <= bit_index + 1;
        end if;

    else
        sample_count <= sample_count + 1;
    end if;

when STOP =>
    data_out <= shift_reg;
    done <= '1';
    state <= IDLE;

end case;

end if;
end process;

end rtl;