library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity execute is
  port (

    clk  : in std_logic;
    rst  : in std_logic;

    -- From DECODE (ID/EX)
    regA_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
    regB_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
    imm_in      : in std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_in       : in std_logic_vector(REG_ADDR_W-1 downto 0);
    pc_in       : in std_logic_vector(PC_WIDTH-1 downto 0);

    RegWrite_in : in std_logic;
    ALUSrc_in   : in std_logic;
    Branch_in   : in std_logic;
    Jump_in     : in std_logic;
    ALUOp_in    : in std_logic_vector(4 downto 0);
    opcode_in   : in std_logic_vector(OPCODE_W-1 downto 0);
	 instr_in    : in std_logic_vector(DATA_WIDTH-1 downto 0);
	 
    -- To next stage
    alu_result_out  	: out std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_out          	: out std_logic_vector(REG_ADDR_W-1 downto 0);
    RegWrite_out    	: out std_logic;
	 regB_out 			: out std_logic_vector(DATA_WIDTH-1 downto 0);

    pc_src_out       : out std_logic;
    pc_target_out    : out std_logic_vector(PC_WIDTH-1 downto 0);
	 instr_out        : out std_logic_vector(DATA_WIDTH-1 downto 0)
	

  );
end entity;

architecture rtl of execute is

  signal operandB     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal alu_res      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal pc_target    : std_logic_vector(PC_WIDTH-1 downto 0);
  signal pc_src       : std_logic;

begin

  ------------------------------------------------------------
  -- ALU operand mux
  ------------------------------------------------------------
  operandB <= imm_in when ALUSrc_in = '1' else regB_in;

  ------------------------------------------------------------
  -- ALU
  ------------------------------------------------------------
  process(regA_in, operandB, ALUOp_in, opcode_in)
	begin
	  case ALUOp_in is

		 ----------------------------------------------------------------
		 -- ADD / ADDU / ADDI / ADDUI
		 ----------------------------------------------------------------
		 when ALU_ADD =>
			if opcode_in = OP_ADDU or opcode_in = OP_ADDUI then
			  alu_res <= std_logic_vector(unsigned(regA_in) + unsigned(operandB));
			else
			  alu_res <= std_logic_vector(signed(regA_in) + signed(operandB));
			end if;

		 ----------------------------------------------------------------
		 -- SUB / SUBU / SUBI / SUBUI
		 ----------------------------------------------------------------
		 when ALU_SUB =>
			if opcode_in = OP_SUBU or opcode_in = OP_SUBUI then
			  alu_res <= std_logic_vector(unsigned(regA_in) - unsigned(operandB));
			else
			  alu_res <= std_logic_vector(signed(regA_in) - signed(operandB));
			end if;

		 ----------------------------------------------------------------
		 -- LOGIC
		 ----------------------------------------------------------------
		 -- AND+ANDI
		 when ALU_AND =>
			alu_res <= regA_in and operandB;
		 -- OR+ORI
		 when ALU_OR =>
			alu_res <= regA_in or operandB;
		 -- XOR+XORI
		 when ALU_XOR =>
			alu_res <= regA_in xor operandB;

		 ----------------------------------------------------------------
		 -- SHIFTS
		 ----------------------------------------------------------------
		 when ALU_SLL =>
			alu_res <= std_logic_vector(
			  shift_left(unsigned(regA_in),
			  to_integer(unsigned(operandB(4 downto 0))))
			);

		 when ALU_SRL =>
			alu_res <= std_logic_vector(
			  shift_right(unsigned(regA_in),
			  to_integer(unsigned(operandB(4 downto 0))))
			);

		 when ALU_SRA =>
			alu_res <= std_logic_vector(
			  shift_right(signed(regA_in),
			  to_integer(unsigned(operandB(4 downto 0))))
			);

		 ----------------------------------------------------------------
		 -- SET LESS THAN
		 ----------------------------------------------------------------
		 when ALU_SLT =>
			if opcode_in = OP_SLTU or opcode_in = OP_SLTUI then
			  if unsigned(regA_in) < unsigned(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			else
			  if signed(regA_in) < signed(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			end if;

		 ----------------------------------------------------------------
		 -- SET GREATER THAN
		 ----------------------------------------------------------------
		 when ALU_SGT =>
			if opcode_in = OP_SGTU or opcode_in = OP_SGTUI then
			  if unsigned(regA_in) > unsigned(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			else
			  if signed(regA_in) > signed(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			end if;

		 ----------------------------------------------------------------
		 -- SET LESS OR EQUAL
		 ----------------------------------------------------------------
		 when ALU_SLE =>
			if opcode_in = OP_SLEU or opcode_in = OP_SLEUI then
			  if unsigned(regA_in) <= unsigned(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			else
			  if signed(regA_in) <= signed(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			end if;

		 ----------------------------------------------------------------
		 -- SET GREATER OR EQUAL
		 ----------------------------------------------------------------
		 when ALU_SGE =>
			if opcode_in = OP_SGEU or opcode_in = OP_SGEUI then
			  if unsigned(regA_in) >= unsigned(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			else
			  if signed(regA_in) >= signed(operandB) then
				 alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			  else
				 alu_res <= (others => '0');
			  end if;
			end if;

		 ----------------------------------------------------------------
		 -- SET EQUAL
		 ----------------------------------------------------------------
		 when ALU_SEQ =>
			if regA_in = operandB then
			  alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			else
			  alu_res <= (others => '0');
			end if;

		 ----------------------------------------------------------------
		 -- SET NOT EQUAL
		 ----------------------------------------------------------------
		 when ALU_SNE =>
			if regA_in /= operandB then
			  alu_res <= (DATA_WIDTH-1 downto 1 => '0') & '1';
			else
			  alu_res <= (others => '0');
			end if;

		 when others =>
			alu_res <= (others => '0');

	  end case;
	end process;


	------------------------------------------------------------
	-- Unified Branch + Jump Control
	------------------------------------------------------------
	process(regA_in, Branch_in, Jump_in, opcode_in, imm_in)
	begin
		 -- defaults
		 pc_target    <= (others => '0');
		 pc_src   <= '0';

		 --------------------------------------------------------
		 -- JUMPS (highest priority)
		 --------------------------------------------------------
		 if Jump_in = '1' then

			  if opcode_in = OP_J or opcode_in = OP_JAL then
					pc_target <= imm_in(PC_WIDTH-1 downto 0);
					pc_src <= '1';

			  elsif opcode_in = OP_JR or opcode_in = OP_JALR then
					pc_target <= regA_in(PC_WIDTH-1 downto 0);
					pc_src <= '1';

			  end if;

		 --------------------------------------------------------
		 -- BRANCHES
		 --------------------------------------------------------
		 elsif Branch_in = '1' then

			  if opcode_in = OP_BEQZ then
					if unsigned(regA_in) = 0 then
						 pc_target    <= imm_in(PC_WIDTH-1 downto 0);
						 pc_src   <= '1';
					end if;

			  elsif opcode_in = OP_BNEZ then
					if unsigned(regA_in) /= 0 then
						 pc_target    <= imm_in(PC_WIDTH-1 downto 0);
						 pc_src   <= '1';
					end if;
			  end if;

		 end if;
	end process;



  ------------------------------------------------------------
  -- Pipeline outputs
  ------------------------------------------------------------
  process(clk)
  begin
	  if rising_edge(clk) then
		 if rst = '1' then
			alu_result_out   <= (others => '0');
			rd_out           <= (others => '0');
			RegWrite_out     <= '0';
			pc_target_out    <= (others => '0');
			instr_out        <= (others => '0');
			pc_src_out       <= '0';
			regB_out 		  <= (others => '0');
		 else
			if opcode_in = OP_JAL or opcode_in = OP_JALR then
			  rd_out         <= std_logic_vector(to_unsigned(31, REG_ADDR_W));
			  alu_result_out <= std_logic_vector(resize(unsigned(pc_in), DATA_WIDTH));
			  RegWrite_out   <= '1';
			else
			  rd_out         <= rd_in;
			  alu_result_out <= alu_res;
			  RegWrite_out   <= RegWrite_in;
			end if;
			pc_target_out    <= pc_target;
			instr_out        <= instr_in;
			pc_src_out       <= pc_src;
			regB_out 		  <= regB_in;
		 end if;
	  end if;
  end process;



end architecture;
