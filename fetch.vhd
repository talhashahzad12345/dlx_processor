library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        mux_sel     : in  std_logic; -- 0 = PC+1, 1 = jump
        jump_addr   : in  std_logic_vector(9 downto 0);
		pc_enable   : in std_logic;

        addr_out    : out std_logic_vector(9 downto 0); -- PC of instr_out+1
        instr_out   : out std_logic_vector(31 downto 0)
    );
end entity fetch;

architecture rtl of fetch is

    -- Fetch PC (drives IMEM)
    signal pc_f     : std_logic_vector(9 downto 0);

    -- Next PC
    signal pc_next    : std_logic_vector(9 downto 0); 
    -- Instruction hold used while fetch is stalled.
    signal imem_q     : std_logic_vector(31 downto 0);
    signal instr_hold : std_logic_vector(31 downto 0);
    signal addr_hold  : std_logic_vector(9 downto 0);
    signal holding    : std_logic;

begin

    --------------------------------------------------------------------
    -- Next-PC logic (from fetch PC)
    --------------------------------------------------------------------
    pc_next <= std_logic_vector(unsigned(pc_f) + 1) when mux_sel = '0'
               else jump_addr;

    --------------------------------------------------------------------
    -- IMEM (synchronous ROM)
    --------------------------------------------------------------------
    imem_inst : entity work.imem
        port map (
            address => pc_f,
            clock   => clk,
            q       => imem_q
        );

    --------------------------------------------------------------------
    -- PC registers
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pc_f <= (others => '0');
                instr_hold <= (others => '0');
                addr_hold <= (others => '0');
                holding <= '0';
            elsif pc_enable = '0' then
                if holding = '0' then
                    instr_hold <= imem_q;
                    addr_hold <= pc_f;
                end if;
                holding <= '1';
            elsif pc_enable = '1' then
                pc_f <= pc_next;
                holding <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Output PC aligned with instr_out
    --------------------------------------------------------------------
    addr_out <= addr_hold when holding = '1' else pc_f;
    instr_out <= instr_hold when holding = '1' else imem_q;

end architecture rtl;
