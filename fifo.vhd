library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity fifo is
  generic (
    WIDTH : integer := PRINT_WIDTH;
    DEPTH : integer := 16
  );
  port(
    clk       : in std_logic;
    rst       : in std_logic;

    wr_en     : in std_logic;
    rd_en     : in std_logic;

    data_in   : in  std_logic_vector(WIDTH-1 downto 0);
    data_out  : out std_logic_vector(WIDTH-1 downto 0);

    full      : out std_logic;
    empty     : out std_logic
  );
end entity;

architecture rtl of fifo is

  type mem_type is array (0 to DEPTH-1)
    of std_logic_vector(WIDTH-1 downto 0);

  signal mem      : mem_type;

  signal wptr     : unsigned(3 downto 0);
  signal rptr     : unsigned(3 downto 0);

  signal count    : unsigned(4 downto 0);
  signal full_s   : std_logic;
  signal empty_s  : std_logic;

begin

  ------------------------------------------------------------
  -- FIFO Read/Write Logic
  ------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then

      if rst='1' then

        wptr  <= (others=>'0');
        rptr  <= (others=>'0');
        count <= (others=>'0');

      else

        --------------------------------------------------
        -- WRITE
        --------------------------------------------------
        if wr_en='1' and full_s='0' then
          mem(to_integer(wptr)) <= data_in;
          wptr <= wptr + 1;
        end if;

        --------------------------------------------------
        -- READ
        --------------------------------------------------
        if rd_en='1' and empty_s='0' then
          rptr <= rptr + 1;
        end if;

        --------------------------------------------------
        -- COUNT UPDATE
        --------------------------------------------------
        if (wr_en='1' and full_s='0') and not (rd_en='1' and empty_s='0') then
          count <= count + 1;

        elsif (rd_en='1' and empty_s='0') and not (wr_en='1' and full_s='0') then
          count <= count - 1;

        end if;

      end if;
    end if;
  end process;

  ------------------------------------------------------------
  -- OUTPUT DATA
  ------------------------------------------------------------
  data_out <= mem(to_integer(rptr));

  ------------------------------------------------------------
  -- STATUS FLAGS
  ------------------------------------------------------------
  full_s <= '1' when count = DEPTH else '0';
  empty_s <= '1' when count = 0 else '0';

  full  <= full_s;
  empty <= empty_s;

end architecture;