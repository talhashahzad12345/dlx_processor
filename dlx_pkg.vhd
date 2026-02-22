library ieee;
use ieee.std_logic_1164.all;

package dlx_pkg is

  ------------------------------------------------------------------
  -- Global parameters
  ------------------------------------------------------------------
  constant DATA_WIDTH : integer := 32;
  constant REG_COUNT  : integer := 32;
  constant REG_ADDR_W : integer := 5;
  constant PC_WIDTH   : integer := 10;

  constant OPCODE_W   : integer := 6;
  constant IMM_W      : integer := 16;

  ------------------------------------------------------------------
  -- DLX Opcodes (6-bit, WIDTH-CORRECT)
  ------------------------------------------------------------------
  constant OP_NOP   : std_logic_vector(5 downto 0) := "000000";

  constant OP_LW    : std_logic_vector(5 downto 0) := "000001";
  constant OP_SW    : std_logic_vector(5 downto 0) := "000010";

  constant OP_ADD   : std_logic_vector(5 downto 0) := "000011";
  constant OP_ADDI  : std_logic_vector(5 downto 0) := "000100";
  constant OP_ADDU  : std_logic_vector(5 downto 0) := "000101";
  constant OP_ADDUI : std_logic_vector(5 downto 0) := "000110";

  constant OP_SUB   : std_logic_vector(5 downto 0) := "000111";
  constant OP_SUBI  : std_logic_vector(5 downto 0) := "001000";
  constant OP_SUBU  : std_logic_vector(5 downto 0) := "001001";
  constant OP_SUBUI : std_logic_vector(5 downto 0) := "001010";

  constant OP_AND   : std_logic_vector(5 downto 0) := "001011";
  constant OP_ANDI  : std_logic_vector(5 downto 0) := "001100";
  constant OP_OR    : std_logic_vector(5 downto 0) := "001101";
  constant OP_ORI   : std_logic_vector(5 downto 0) := "001110";
  constant OP_XOR   : std_logic_vector(5 downto 0) := "001111";
  constant OP_XORI  : std_logic_vector(5 downto 0) := "010000";

  constant OP_SLL   : std_logic_vector(5 downto 0) := "010001";
  constant OP_SLLI  : std_logic_vector(5 downto 0) := "010010";
  constant OP_SRL   : std_logic_vector(5 downto 0) := "010011";
  constant OP_SRLI  : std_logic_vector(5 downto 0) := "010100";
  constant OP_SRA   : std_logic_vector(5 downto 0) := "010101";
  constant OP_SRAI  : std_logic_vector(5 downto 0) := "010110";

  constant OP_SLT   : std_logic_vector(5 downto 0) := "010111";
  constant OP_SLTI  : std_logic_vector(5 downto 0) := "011000";
  constant OP_SLTU  : std_logic_vector(5 downto 0) := "011001";
  constant OP_SLTUI : std_logic_vector(5 downto 0) := "011010";

  constant OP_SGT   : std_logic_vector(5 downto 0) := "011011";
  constant OP_SGTI  : std_logic_vector(5 downto 0) := "011100";
  constant OP_SGTU  : std_logic_vector(5 downto 0) := "011101";
  constant OP_SGTUI : std_logic_vector(5 downto 0) := "011110";

  constant OP_SLE   : std_logic_vector(5 downto 0) := "011111";
  constant OP_SLEI  : std_logic_vector(5 downto 0) := "100000";
  constant OP_SLEU  : std_logic_vector(5 downto 0) := "100001";
  constant OP_SLEUI : std_logic_vector(5 downto 0) := "100010";

  constant OP_SGE   : std_logic_vector(5 downto 0) := "100011";
  constant OP_SGEI  : std_logic_vector(5 downto 0) := "100100";
  constant OP_SGEU  : std_logic_vector(5 downto 0) := "100101";
  constant OP_SGEUI : std_logic_vector(5 downto 0) := "100110";

  constant OP_SEQ   : std_logic_vector(5 downto 0) := "100111";
  constant OP_SEQI  : std_logic_vector(5 downto 0) := "101000";
  constant OP_SNE   : std_logic_vector(5 downto 0) := "101001";
  constant OP_SNEI  : std_logic_vector(5 downto 0) := "101010";

  constant OP_BEQZ  : std_logic_vector(5 downto 0) := "101011";
  constant OP_BNEZ  : std_logic_vector(5 downto 0) := "101100";

  constant OP_J     : std_logic_vector(5 downto 0) := "101101";
  constant OP_JR    : std_logic_vector(5 downto 0) := "101110";
  constant OP_JAL   : std_logic_vector(5 downto 0) := "101111";
  constant OP_JALR  : std_logic_vector(5 downto 0) := "110000";

  ------------------------------------------------------------------
  -- ALU operation encodings (internal)
  ------------------------------------------------------------------
  constant ALU_ADD  : std_logic_vector(4 downto 0) := "00000";
  constant ALU_SUB  : std_logic_vector(4 downto 0) := "00001";
  constant ALU_AND  : std_logic_vector(4 downto 0) := "00010";
  constant ALU_OR   : std_logic_vector(4 downto 0) := "00011";
  constant ALU_XOR  : std_logic_vector(4 downto 0) := "00100";
  constant ALU_SLL  : std_logic_vector(4 downto 0) := "00101";
  constant ALU_SRL  : std_logic_vector(4 downto 0) := "00110";
  constant ALU_SRA  : std_logic_vector(4 downto 0) := "00111";

  constant ALU_SLT  : std_logic_vector(4 downto 0) := "01000";
  constant ALU_SGT  : std_logic_vector(4 downto 0) := "01001";
  constant ALU_SLE  : std_logic_vector(4 downto 0) := "01010";
  constant ALU_SGE  : std_logic_vector(4 downto 0) := "01011";
  constant ALU_SEQ  : std_logic_vector(4 downto 0) := "01100";
  constant ALU_SNE  : std_logic_vector(4 downto 0) := "01101";

end package dlx_pkg;
