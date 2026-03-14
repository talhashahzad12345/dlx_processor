library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity dlx is
  port (
    clk : in std_logic;
    rst : in std_logic
  );
end entity dlx;

architecture rtl of dlx is

  ------------------------------------------------------------------
  -- FETCH → DECODE
  ------------------------------------------------------------------
  signal instr_f : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal pc_f    : std_logic_vector(PC_WIDTH-1 downto 0);

  ------------------------------------------------------------------
  -- DECODE → EXECUTE
  ------------------------------------------------------------------
  signal regA_d     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal regB_d     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal imm_d      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_d       : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal pc_d       : std_logic_vector(PC_WIDTH-1 downto 0);

  signal RegWrite_d : std_logic;
  signal ALUSrc_d   : std_logic;
  signal Branch_d   : std_logic;
  signal Jump_d     : std_logic;
  signal ALUOp_d    : std_logic_vector(4 downto 0);
  signal opcode_d   : std_logic_vector(OPCODE_W-1 downto 0);
  signal instr_d    : std_logic_vector(DATA_WIDTH-1 downto 0);

  ------------------------------------------------------------------
  -- EXECUTE → MEMORY
  ------------------------------------------------------------------
  signal alu_e        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_e         : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal regB_e       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal RegWrite_e   : std_logic;
  signal instr_e      : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal pc_target_e  : std_logic_vector(PC_WIDTH-1 downto 0);
  signal pc_src_e     : std_logic;

  ------------------------------------------------------------------
  -- MEMORY → WRITEBACK
  ------------------------------------------------------------------
  signal mem_data_m   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal alu_m        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_m         : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal RegWrite_m   : std_logic;
  signal instr_m      : std_logic_vector(DATA_WIDTH-1 downto 0);

  ------------------------------------------------------------------
  -- WRITEBACK → DECODE
  ------------------------------------------------------------------
  signal wb_we      : std_logic;
  signal wb_addr    : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal wb_data    : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  ------------------------------------------------------------------
  -- FORWARDING
  ------------------------------------------------------------------
  signal rs1_d      : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal rs2_d      : std_logic_vector(REG_ADDR_W-1 downto 0);
  
  signal forwardA   : std_logic_vector(1 downto 0);
  signal forwardB   : std_logic_vector(1 downto 0);
  
  signal rs1_exec : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal rs2_exec : std_logic_vector(REG_ADDR_W-1 downto 0);
  
  ------------------------------------------------------------------
  -- STALL
  ------------------------------------------------------------------
  signal is_load_e   : std_logic;
  signal stall       : std_logic;
  signal pc_enable_s : std_logic;
  
  ------------------------------------------------------------------
  -- FLUSH
  ------------------------------------------------------------------
  signal flush 			: std_logic;
  signal instr_f_mux 	: std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal instr_d_mux		: std_logic_vector(DATA_WIDTH-1 downto 0);
  signal RegWrite_d_mux : std_logic;
  signal Branch_d_mux   : std_logic;
  signal Jump_d_mux     : std_logic;
  signal ALUSrc_d_mux   : std_logic;
  signal ALUOp_d_mux    : std_logic_vector(4 downto 0);
  signal rd_d_mux       : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal regA_d_mux     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal regB_d_mux     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal imm_d_mux      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal opcode_d_mux 	: std_logic_vector(OPCODE_W-1 downto 0);
  signal pc_d_mux       : std_logic_vector(PC_WIDTH-1 downto 0);
  
  signal flush_d : std_logic;
  
begin

  ------------------------------------------------------------------
  -- FLUSH
  ------------------------------------------------------------------
  process(clk)
	begin
	  if rising_edge(clk) then
		  flush_d <= flush;
	  end if;
	end process;
  
  flush 			 <= pc_src_e;
  instr_f_mux <= (others => '0') when (flush='1' or flush_d='1')
               else instr_f;
  
  -- Kill instruction already in ID when branch taken
  instr_d_mux   <= (others => '0') when flush='1' else instr_d;
  RegWrite_d_mux<= '0' when flush='1' else RegWrite_d;
  Branch_d_mux  <= '0' when flush='1' else Branch_d;
  Jump_d_mux    <= '0' when flush='1' else Jump_d;
  ALUSrc_d_mux  <= '0' when flush='1' else ALUSrc_d;
  ALUOp_d_mux   <= (others=>'0') when flush='1' else ALUOp_d;

  rd_d_mux      <= (others=>'0') when flush='1' else rd_d;
  regA_d_mux    <= (others=>'0') when flush='1' else regA_d;
  regB_d_mux    <= (others=>'0') when flush='1' else regB_d;
  imm_d_mux     <= (others=>'0') when flush='1' else imm_d;
  opcode_d_mux	 <= (others=>'0') when flush='1' else opcode_d;
  pc_d_mux      <= pc_d;
  
  
  ------------------------------------------------------------------
  -- FORWARDING
  ------------------------------------------------------------------
  rs1_exec <= (others => '0') when flush='1' else rs1_d;
  rs2_exec <= (others => '0') when flush='1' else rs2_d;

  process(rs1_exec, rs2_exec, rd_e, rd_m, RegWrite_e, RegWrite_m)
	begin
		 forwardA <= "00";
		 forwardB <= "00";

		 -- MEM stage forwarding (priority)
		 if RegWrite_m = '1' and rd_m /= "00000" and rd_m = rs1_exec then
			  forwardA <= "10";
		 elsif RegWrite_e = '1' and rd_e /= "00000" and rd_e = rs1_exec then
			  forwardA <= "01";
		 end if;

		 if RegWrite_m = '1' and rd_m /= "00000" and rd_m = rs2_exec then
			  forwardB <= "10";
		 elsif RegWrite_e = '1' and rd_e /= "00000" and rd_e = rs2_exec then
			  forwardB <= "01";
		 end if;
	end process;

	
  ------------------------------------------------------------------
  -- LOAD-USE HAZARD DETECTION
  ------------------------------------------------------------------

  is_load_e <= '1' when instr_e(31 downto 26) = OP_LW else '0';

  stall <= '1' when
	(is_load_e = '1') and
		(
			(rd_e = rs1_d) or
			(rd_e = rs2_d and ALUSrc_d = '0')
		)
  else '0';


  pc_enable_s <= not stall;
  ------------------------------------------------------------------
  -- FETCH
  ------------------------------------------------------------------
  fetch_inst : entity work.fetch
    port map (
      clk       => clk,
      rst       => rst,
      mux_sel   => pc_src_e,
      jump_addr => pc_target_e,
		pc_enable => pc_enable_s,
      addr_out  => pc_f,
      instr_out => instr_f
    );

  ------------------------------------------------------------------
  -- DECODE
  ------------------------------------------------------------------
  decode_inst : entity work.decode
    port map (
      clk        => clk,
      rst        => rst,
      instr_in   => instr_f_mux,
      pc_in      => pc_f,

      wb_we      => wb_we,
      wb_addr    => wb_addr,
      wb_data    => wb_data,

      regA_out   => regA_d,
      regB_out   => regB_d,
      imm_out    => imm_d,
      rs1_out    => rs1_d,
      rs2_out    => rs2_d,
      rd_out     => rd_d,
      pc_out     => pc_d,

      RegWrite_out => RegWrite_d,
      ALUSrc_out   => ALUSrc_d,
      Branch_out   => Branch_d,
      Jump_out     => Jump_d,
      ALUOp_out    => ALUOp_d,
      opcode_out   => opcode_d,
      instr_out    => instr_d,
		
		flush_in     => flush,
		stall_in		 => stall
    );

  ------------------------------------------------------------------
  -- EXECUTE
  ------------------------------------------------------------------
  execute_inst : entity work.execute
    port map (
      clk => clk,
      rst => rst,

      regA_in      => regA_d_mux,
      regB_in      => regB_d_mux,
      imm_in       => imm_d_mux,
      rd_in        => rd_d_mux,
      pc_in        => pc_d_mux,

      RegWrite_in  => RegWrite_d_mux,
      ALUSrc_in    => ALUSrc_d_mux,
      Branch_in    => Branch_d_mux,
      Jump_in      => Jump_d_mux,
      ALUOp_in     => ALUOp_d_mux,
      opcode_in    => opcode_d_mux,
      instr_in     => instr_d_mux,

      alu_result_out => alu_e,
      rd_out         => rd_e,
      RegWrite_out   => RegWrite_e,
      regB_out       => regB_e,
      pc_src_out     => pc_src_e,
      pc_target_out  => pc_target_e,
      instr_out      => instr_e,
		
		forwardA       => forwardA,
		forwardB       => forwardB,
		alu_forward    => alu_e,
		wb_forward     => alu_m,
		rs1_in 			=> rs1_exec,
		rs2_in 			=> rs2_exec
    );

  ------------------------------------------------------------------
  -- MEMORY
  ------------------------------------------------------------------
  memory_inst : entity work.memory
    port map (
      clk           => clk,
      rst           => rst,
      instr_in      => instr_e,
      alu_result_in => alu_e,
      regB_data_in  => regB_e,
      reg_write_in  => RegWrite_e,
		rd_in			  => rd_e,
      mem_data_out  => mem_data_m,
      alu_out       => alu_m,
      rd_out        => rd_m,
      reg_write_out => RegWrite_m,
      instr_out     => instr_m
    );

  ------------------------------------------------------------------
  -- WRITEBACK
  ------------------------------------------------------------------
  writeback_inst : entity work.writeback
    port map (
      instr_in      => instr_m,
      mem_data_in   => mem_data_m,
      alu_data_in   => alu_m,
      rd_in         => rd_m,
      reg_write_in  => RegWrite_m,
      wb_we         => wb_we,
      wb_addr       => wb_addr,
      wb_data       => wb_data
    );

end architecture rtl;