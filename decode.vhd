library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity decode is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;

    -- From FETCH
    instr_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    pc_in     : in  std_logic_vector(PC_WIDTH-1 downto 0);

    -- Writeback support (TB or WB stage)
    wb_we     : in  std_logic;
    wb_addr   : in  std_logic_vector(REG_ADDR_W-1 downto 0);
    wb_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- To EXECUTE (ID/EX)
    regA_out  : out std_logic_vector(DATA_WIDTH-1 downto 0); --dataA
    regB_out  : out std_logic_vector(DATA_WIDTH-1 downto 0); --dataB
    imm_out   : out std_logic_vector(DATA_WIDTH-1 downto 0);

    rs1_out   : out std_logic_vector(REG_ADDR_W-1 downto 0); --regA
    rs2_out   : out std_logic_vector(REG_ADDR_W-1 downto 0); --regB
    rd_out    : out std_logic_vector(REG_ADDR_W-1 downto 0); --OUTPUT Reg

    pc_out    : out std_logic_vector(PC_WIDTH-1 downto 0);

    -- Control signals
    RegWrite_out : out std_logic;
    ALUSrc_out   : out std_logic;
    Branch_out   : out std_logic;
    Jump_out     : out std_logic;
    ALUOp_out    : out std_logic_vector(4 downto 0);
	 -- To EXECUTE (ID/EX)
	 opcode_out   : out std_logic_vector(OPCODE_W-1 downto 0);
	 instr_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
	 
	 --stall
	 stall_in 	  : in std_logic;
	 --flush
	 flush_in 	  : in std_logic
  );
end entity decode;

architecture rtl of decode is

  ------------------------------------------------------------------
  -- Instruction fields
  ------------------------------------------------------------------
  signal opcode : std_logic_vector(OPCODE_W-1 downto 0);
  signal rd     : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal rs1    : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal rs2    : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal imm16  : std_logic_vector(IMM_W-1 downto 0);

  ------------------------------------------------------------------
  -- Register file outputs
  ------------------------------------------------------------------
  signal regA   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal regB   : std_logic_vector(DATA_WIDTH-1 downto 0);

  ------------------------------------------------------------------
  -- Sign-extended immediate
  ------------------------------------------------------------------
  signal imm_ext      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal imm_zero_ext : std_logic;

  ------------------------------------------------------------------
  -- Decoded control signals
  ------------------------------------------------------------------
  signal RegWrite 	: std_logic;
  signal ALUSrc   	: std_logic;
  signal Branch   	: std_logic;
  signal Jump     	: std_logic;
  signal ALUOp    	: std_logic_vector(4 downto 0);
  signal ra2_mux  	: std_logic_vector(REG_ADDR_W-1 downto 0);
  signal rs1_actual 	: std_logic_vector(REG_ADDR_W-1 downto 0);
  signal jump_addr   : std_logic_vector(25 downto 0);
  signal jump_reg    : std_logic_vector(REG_ADDR_W-1 downto 0);
  signal imm_actual  : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  ------------------------------------------------------------------
  -- Forwarding
  ------------------------------------------------------------------
  signal regA_final : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal regB_final : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  -- WB → ID forwarding
  regA_final <= wb_data when (wb_we = '1' and wb_addr = rs1_actual and wb_addr /= "00000")
					  else regA;

  regB_final <= wb_data when (wb_we = '1' and wb_addr = ra2_mux and wb_addr /= "00000")
					  else regB;

  ------------------------------------------------------------------
  -- Instruction field extraction
  ------------------------------------------------------------------
  jump_addr <= instr_in(25 downto 0) ;
  jump_reg  <= instr_in(4 downto 0)  ;
  opcode  	<= instr_in(31 downto 26);
  rd      	<= instr_in(25 downto 21);
  rs1     	<= instr_in(20 downto 16);
  rs2     	<= instr_in(15 downto 11);
  imm16   	<= instr_in(15 downto 0);
  ra2_mux 	<= rd when opcode = OP_SW else rs2;
  -- For branches, register is stored in rd field
  rs1_actual <=
    rd when (opcode = OP_BEQZ or opcode = OP_BNEZ) else
    jump_reg when (opcode = OP_JR or opcode = OP_JALR) else
    rs1;

  ------------------------------------------------------------------
  -- Register file
  ------------------------------------------------------------------
  rf_inst : entity work.regfile
    port map (
      clk => clk,
      we  => wb_we,
      ra1 => rs1_actual,
      ra2 => ra2_mux,
      wa  => wb_addr,
      wd  => wb_data,
      rd1 => regA,
      rd2 => regB
    );

  ------------------------------------------------------------------
  -- Control unit (decode logic)
  ------------------------------------------------------------------
  process(opcode)
	begin
	  -- Defaults
	  RegWrite <= '0';
	  ALUSrc   <= '0';
	  Branch   <= '0';
	  Jump     <= '0';
	  ALUOp    <= ALU_ADD;
	  imm_zero_ext <= '0';   -- default = SIGN extend

	  case opcode is

		 -- =========================
		 -- No operation
		 -- =========================
		 when OP_NOP =>
			null;

		 -- =========================
		 -- Register-register ALU ops
		 -- =========================
		 when OP_ADD  => RegWrite <= '1'; ALUOp <= ALU_ADD;
		 when OP_ADDU =>
		  RegWrite     <= '1';
		  ALUOp        <= ALU_ADD;
		  imm_zero_ext <= '1';

		 when OP_SUB  => RegWrite <= '1'; ALUOp <= ALU_SUB;
		 when OP_SUBU =>
		  RegWrite     <= '1';
		  ALUOp        <= ALU_SUB;
		  imm_zero_ext <= '1';

		 when OP_AND  => RegWrite <= '1'; ALUOp <= ALU_AND;
		 when OP_OR   => RegWrite <= '1'; ALUOp <= ALU_OR;
		 when OP_XOR  => RegWrite <= '1'; ALUOp <= ALU_XOR;

		 when OP_SLL  => RegWrite <= '1'; ALUOp <= ALU_SLL; imm_zero_ext <= '1';
		 when OP_SRL  => RegWrite <= '1'; ALUOp <= ALU_SRL; imm_zero_ext <= '1';
		 when OP_SRA  => RegWrite <= '1'; ALUOp <= ALU_SRA;

		 -- =========================
		 -- Immediate ALU ops
		 -- =========================
		 when OP_ADDI  => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_ADD;
		 when OP_ADDUI => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_ADD; imm_zero_ext <= '1';

		 when OP_SUBI  => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SUB;
		 when OP_SUBUI => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SUB; imm_zero_ext <= '1';
		 
		 when OP_ANDI =>
		  RegWrite     <= '1';
		  ALUSrc       <= '1';
		  ALUOp        <= ALU_AND;
		  imm_zero_ext <= '1';

		 when OP_ORI =>
		  RegWrite     <= '1';
		  ALUSrc       <= '1';
		  ALUOp        <= ALU_OR;
		  imm_zero_ext <= '1';

		 when OP_XORI =>
		  RegWrite     <= '1';
		  ALUSrc       <= '1';
		  ALUOp        <= ALU_XOR;
		  imm_zero_ext <= '1';

		 when OP_SLLI  => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SLL; imm_zero_ext <= '1';
		 when OP_SRLI  => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SRL; imm_zero_ext <= '1';
		 when OP_SRAI  => RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SRA;

		 -- =========================
		 -- Set / compare ops
		 -- =========================
		 when OP_SLT =>
			RegWrite <= '1'; ALUOp <= ALU_SLT;
		 when OP_SLTI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SLT;
			
		 when OP_SLTU => 
			RegWrite <= '1'; ALUOp <= ALU_SLT; imm_zero_ext <= '1';
		 when OP_SLTUI => 
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SLT; imm_zero_ext <= '1';
			
		 when OP_SGT =>
			RegWrite <= '1'; ALUOp <= ALU_SGT;
		 when OP_SGTI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SGT;
			
		 when OP_SGTU =>
			RegWrite <= '1'; ALUOp <= ALU_SGT; imm_zero_ext <= '1';
		 when OP_SGTUI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SGT; imm_zero_ext <= '1';
			
		 when OP_SLE =>
			RegWrite <= '1'; ALUOp <= ALU_SLE;
		 when OP_SLEI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SLE;
			
		 when OP_SLEU =>
			RegWrite <= '1'; ALUOp <= ALU_SLE; imm_zero_ext <= '1';
		 when OP_SLEUI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SLE; imm_zero_ext <= '1';
			
		 when OP_SGE =>
			RegWrite <= '1'; ALUOp <= ALU_SGE;
		 when OP_SGEI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SGE;
			
		 when OP_SGEU =>
			RegWrite <= '1'; ALUOp <= ALU_SGE; imm_zero_ext <= '1';
			
		 when OP_SGEUI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SGE; imm_zero_ext <= '1';
			
		 when OP_SEQ => 
			RegWrite <= '1'; ALUOp <= ALU_SEQ;
		 when OP_SEQI => 
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SEQ;

		 when OP_SNE =>
			RegWrite <= '1'; ALUOp <= ALU_SNE;
		 when OP_SNEI =>
			RegWrite <= '1'; ALUSrc <= '1'; ALUOp <= ALU_SNE;

		 -- =========================
		 -- Memory
		 -- =========================
		 when OP_LW =>
			RegWrite <= '1';
			ALUSrc   <= '1';
			ALUOp    <= ALU_ADD;

		 when OP_SW =>
			RegWrite <= '0';
			ALUSrc   <= '1';
			ALUOp    <= ALU_ADD;

		 -- =========================
		 -- Branch / Jump
		 -- =========================
		 when OP_BEQZ | OP_BNEZ =>
			Branch <= '1';

		 when OP_J =>
			Jump <= '1';

		 when OP_JR =>
			Jump <= '1';

	 	 when OP_JAL =>
			Jump <= '1';
			RegWrite <= '1';

		 when OP_JALR =>
			Jump <= '1';
			RegWrite <= '1';


		 when others =>
			null;

	  end case;
	end process;

	
	
	------------------------------------------------------------------
	-- Immediate extension (DLX correct behavior)
	-- Arithmetic immediates = sign extend
	-- Logical immediates (ANDI/ORI/XORI) = zero extend
	------------------------------------------------------------------
	process(imm16, imm_zero_ext)
	begin
	  if imm_zero_ext = '1' then
		 imm_ext <= std_logic_vector(resize(unsigned(imm16), DATA_WIDTH));
	  else
		 imm_ext <= std_logic_vector(resize(signed(imm16), DATA_WIDTH));
	  end if;
	end process;
	--but jump
	imm_actual <=
    std_logic_vector(resize(unsigned(jump_addr), DATA_WIDTH))
        when (opcode = OP_J or opcode = OP_JAL or
              opcode = OP_BEQZ or opcode = OP_BNEZ)
    else
        imm_ext;
--	imm_actual <=
--    std_logic_vector(resize(unsigned(jump_addr), DATA_WIDTH))
--        when (opcode = OP_J or opcode = OP_JAL)
--    else
--        imm_ext;

	
  ------------------------------------------------------------------
  -- ID/EX pipeline register
  ------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regA_out     <= (others => '0');
        regB_out     <= (others => '0');
        imm_out      <= (others => '0');
        rs1_out      <= (others => '0');
        rs2_out      <= (others => '0');
        rd_out       <= (others => '0');
        pc_out       <= (others => '0');

        RegWrite_out <= '0';
        ALUSrc_out   <= '0';
        Branch_out   <= '0';
        Jump_out     <= '0';
        ALUOp_out    <= (others => '0');
		  opcode_out   <= (others => '0');
		  instr_out    <= (others => '0');

--		elsif flush_in = '1' then
--
--		  regA_out     <= (others => '0');
--		  regB_out     <= (others => '0');
--		  imm_out      <= (others => '0');
--		  rs1_out      <= (others => '0');
--		  rs2_out      <= (others => '0');
--		  rd_out       <= (others => '0');
--		  pc_out       <= (others => '0');
--		  
--		  RegWrite_out <= '0';
--		  ALUSrc_out   <= '0';
--		  Branch_out   <= '0';
--		  Jump_out     <= '0';
--		  ALUOp_out    <= (others => '0');
--		  opcode_out   <= OP_NOP;
--		  instr_out    <= (others => '0');
		  
		elsif stall_in = '1' then
		  -- INSERT BUBBLE
		  regA_out     <= (others => '0');
		  regB_out     <= (others => '0');
		  imm_out      <= (others => '0');
		  rs1_out      <= (others => '0');
		  rs2_out      <= (others => '0');
		  rd_out       <= (others => '0');
		  pc_out       <= (others => '0');

		  RegWrite_out <= '0';
		  ALUSrc_out   <= '0';
		  Branch_out   <= '0';
		  Jump_out     <= '0';
		  ALUOp_out    <= (others => '0');
		  opcode_out   <= OP_NOP;
		  instr_out    <= (others => '0');

      else
        regA_out     <= regA_final;
        regB_out     <= regB_final;
        imm_out      <= imm_actual;
        rs1_out      <= rs1_actual;
        rs2_out      <= rs2;
        rd_out       <= rd;
        pc_out       <= pc_in;

        RegWrite_out <= RegWrite;
        ALUSrc_out   <= ALUSrc;
        Branch_out   <= Branch;
        Jump_out     <= Jump;
        ALUOp_out    <= ALUOp;
		  opcode_out   <= opcode;
		  instr_out    <= instr_in;

      end if;
    end if;
  end process;

end architecture rtl;
