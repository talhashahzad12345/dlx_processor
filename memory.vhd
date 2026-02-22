library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity memory is
  port (

    clk 	: in std_logic;
	 rst  : in std_logic;

    -- From EXECUTE
    instr_in         : in  std_logic_vector(31 downto 0);
    alu_result_in    : in  std_logic_vector(31 downto 0);
    regB_data_in     : in  std_logic_vector(31 downto 0);
	 reg_write_in		: in  std_logic;
	 rd_in     	   	: in  std_logic_vector(4 downto 0);

    -- To WRITEBACK
    mem_data_out	   : out std_logic_vector(31 downto 0);
    alu_out     	   : out std_logic_vector(31 downto 0);
    rd_out     	   : out std_logic_vector(4 downto 0);
    reg_write_out 	: out std_logic;
	 instr_out        : out std_logic_vector(31 downto 0)
  );
end memory;

architecture rtl of memory is

  signal opcode  : std_logic_vector(5 downto 0);
  signal ram_q   : std_logic_vector(31 downto 0);
  signal wren    : std_logic;

begin

  opcode <= instr_in(31 downto 26);

  ----------------------------------------------------------------
  -- Determine if store word
  ----------------------------------------------------------------
  wren <= '1' when opcode = OP_SW else '0';  -- SW = 0x02

  ----------------------------------------------------------------
  -- Data Memory
  ----------------------------------------------------------------
  dmem_inst : entity work.dmem
    port map (
      address => alu_result_in(9 downto 0),
      clock   => clk,
      data    => regB_data_in,
      wren    => wren,
      q       => ram_q
    );
  
  ------------------------------------------------------------
  -- MEM/WB pipeline register
  ------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
		if rst = '1' then
			alu_out   	  <= (others => '0');
			rd_out        <= (others => '0');
			reg_write_out <= '0';
			instr_out	  <= (others => '0');
		else
			alu_out   	  <= alu_result_in;
			rd_out        <= rd_in;
			reg_write_out <= reg_write_in;
			instr_out	  <= instr_in;
		end if;
    end if;
  end process;
  mem_data_out  		  <= ram_q;

end rtl;