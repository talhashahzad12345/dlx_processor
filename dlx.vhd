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
  signal wb_we   : std_logic;
  signal wb_addr : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal wb_data : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  ------------------------------------------------------------------
  -- FETCH
  ------------------------------------------------------------------
  fetch_inst : entity work.fetch
    port map (
      clk       => clk,
      rst       => rst,
      mux_sel   => pc_src_e,
      jump_addr => pc_target_e,
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
      instr_in   => instr_f,
      pc_in      => pc_f,

      wb_we      => wb_we,
      wb_addr    => wb_addr,
      wb_data    => wb_data,

      regA_out   => regA_d,
      regB_out   => regB_d,
      imm_out    => imm_d,
      rs1_out    => open,
      rs2_out    => open,
      rd_out     => rd_d,
      pc_out     => pc_d,

      RegWrite_out => RegWrite_d,
      ALUSrc_out   => ALUSrc_d,
      Branch_out   => Branch_d,
      Jump_out     => Jump_d,
      ALUOp_out    => ALUOp_d,
      opcode_out   => opcode_d,
      instr_out    => instr_d
    );

  ------------------------------------------------------------------
  -- EXECUTE
  ------------------------------------------------------------------
  execute_inst : entity work.execute
    port map (
      clk => clk,
      rst => rst,

      regA_in      => regA_d,
      regB_in      => regB_d,
      imm_in       => imm_d,
      rd_in        => rd_d,
      pc_in        => pc_d,

      RegWrite_in  => RegWrite_d,
      ALUSrc_in    => ALUSrc_d,
      Branch_in    => Branch_d,
      Jump_in      => Jump_d,
      ALUOp_in     => ALUOp_d,
      opcode_in    => opcode_d,
      instr_in     => instr_d,

      alu_result_out => alu_e,
      rd_out         => rd_e,
      RegWrite_out   => RegWrite_e,
      regB_out       => regB_e,
      pc_src_out     => pc_src_e,
      pc_target_out  => pc_target_e,
      instr_out      => instr_e
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