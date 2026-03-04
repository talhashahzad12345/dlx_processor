library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dlx is
end entity;

architecture sim of tb_dlx is

  ------------------------------------------------------------------
  -- Clock / Reset
  ------------------------------------------------------------------
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

begin

  ------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------
  dut : entity work.dlx
    port map (
      clk => clk,
      rst => rst
    );

  ------------------------------------------------------------------
  -- Clock generation (20 ns period)
  ------------------------------------------------------------------
  clk <= not clk after 10 ns;

  ------------------------------------------------------------------
  -- Reset sequence
  ------------------------------------------------------------------
  process
  begin
    rst <= '1';
    wait for 40 ns;
    rst <= '0';
	 
    wait;
  end process;

end architecture;