library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity print_engine is
  port(
    clk : in std_logic;
    rst : in std_logic;

    -- INPUT FIFO
    fifo_in_data  : in  std_logic_vector(PRINT_WIDTH-1 downto 0);
    fifo_in_empty : in  std_logic;
    fifo_in_rd    : out std_logic;

    -- OUTPUT FIFO (to UART)
    fifo_out_data : out std_logic_vector(7 downto 0);
    fifo_out_wr   : out std_logic;
    fifo_out_full : in  std_logic
  );
end entity;

architecture rtl of print_engine is
  
  type state_t is (
    IDLE,
    READ,
    CHECK_TYPE,

    SEND_CHAR,

    HANDLE_SIGN,
    START_DIV,
    WAIT_DIV,
    STORE_DIGIT,
    CHECK_DONE,

    OUTPUT_SIGN,
    OUTPUT_DIGIT,

    DONE
  );

  signal state : state_t;

  -- input decoding
  signal pkt_type  : std_logic_vector(1 downto 0);
  signal value_reg : unsigned(31 downto 0);

  -- sign handling
  signal is_negative : std_logic;

  -- divider
  signal numer_reg : std_logic_vector(31 downto 0);
  signal quotient  : std_logic_vector(31 downto 0);
  signal remainder : std_logic_vector(3 downto 0);

  -- latency tracking (4 cycles)
  signal div_valid_shift : std_logic_vector(3 downto 0);

  -- digit buffer
  type digit_array is array(0 to 10) of std_logic_vector(7 downto 0);
  signal digits : digit_array;

  signal digit_count : integer range 0 to 10;
  signal out_index   : integer range 0 to 10;

  -- edge case
  signal is_int_min : std_logic;

  signal div_start : std_logic;

begin

  ------------------------------------------------------------
  -- Divider instance
  ------------------------------------------------------------
  div_inst : entity work.div
    port map (
      clock    => clk,
      numer    => numer_reg,
      denom    => "1010",
      quotient => quotient,
      remain   => remainder
    );

  ------------------------------------------------------------
  -- Divider latency tracker
  ------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        div_valid_shift <= (others=>'0');
      else
        if div_start = '1' then
          div_valid_shift <= "0001";  -- start pulse
        else
          div_valid_shift <= div_valid_shift(2 downto 0) & '0';
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------
  -- FSM
  ------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        state <= IDLE;
        fifo_in_rd  <= '0';
        fifo_out_wr <= '0';

      else

        -- defaults
        fifo_in_rd  <= '0';
        fifo_out_wr <= '0';

        case state is

        --------------------------------------------------
        when IDLE =>
          if fifo_in_empty = '0' and fifo_out_full = '0' then
            fifo_in_rd <= '1';
            state <= READ;
          end if;

        --------------------------------------------------
        when READ =>
          pkt_type <= fifo_in_data(33 downto 32);
          state <= CHECK_TYPE;

        --------------------------------------------------
        when CHECK_TYPE =>

          -- CHAR
          if pkt_type = "00" then
            fifo_out_data <= fifo_in_data(7 downto 0);
            state <= SEND_CHAR;

          else
            -- INT PATH
            digit_count <= 0;

            -- INT_MIN detection
            if fifo_in_data(31 downto 0) = x"80000000" then
              is_int_min <= '1';
              is_negative <= '1';
              value_reg <= to_unsigned(2147483648, 32); -- abs(INT_MIN)
            else
              is_int_min <= '0';

              if pkt_type = "01" and fifo_in_data(31) = '1' then
                -- negative
                is_negative <= '1';
                value_reg <= unsigned(not fifo_in_data(31 downto 0)) + 1;
              else
                is_negative <= '0';
                value_reg <= unsigned(fifo_in_data(31 downto 0));
              end if;
            end if;

            state <= START_DIV;
          end if;

        --------------------------------------------------
        when SEND_CHAR =>
          if fifo_out_full = '0' then
            fifo_out_wr <= '1';
            state <= IDLE;
          end if;

        --------------------------------------------------
        -- INTEGER PATH
        --------------------------------------------------
        when START_DIV =>
          numer_reg <= std_logic_vector(value_reg);
          div_start <= '1';
          state <= WAIT_DIV;

        --------------------------------------------------
        when WAIT_DIV =>
          if div_valid_shift(3) = '1' then
            state <= STORE_DIGIT;
          end if;

        --------------------------------------------------
        when STORE_DIGIT =>
          digits(digit_count) <= std_logic_vector(
            to_unsigned(48,8) + unsigned(remainder)
          );

          digit_count <= digit_count + 1;
          value_reg <= unsigned(quotient);
          state <= CHECK_DONE;

        --------------------------------------------------
        when CHECK_DONE =>
          if unsigned(quotient) = 0 then
            out_index <= digit_count - 1;

            if is_negative = '1' then
              state <= OUTPUT_SIGN;
            else
              state <= OUTPUT_DIGIT;
            end if;
          else
            state <= START_DIV;
          end if;

        --------------------------------------------------
        when OUTPUT_SIGN =>
          if fifo_out_full = '0' then
            fifo_out_data <= x"2D"; -- '-'
            fifo_out_wr <= '1';
            state <= OUTPUT_DIGIT;
          end if;

        --------------------------------------------------
        when OUTPUT_DIGIT =>
          if fifo_out_full = '0' then
            fifo_out_data <= digits(out_index);
            fifo_out_wr <= '1';

            if out_index = 0 then
              state <= DONE;
            else
              out_index <= out_index - 1;
            end if;
          end if;

        --------------------------------------------------
        when DONE =>
          state <= IDLE;

        end case;

      end if;
    end if;
  end process;

end architecture;