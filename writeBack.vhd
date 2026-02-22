library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dlx_pkg.all;

entity writeback is
  port (

    -- From MEMORY
    instr_in        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    mem_data_in     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    alu_data_in     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_in           : in  std_logic_vector(REG_ADDR_W-1 downto 0);
    reg_write_in    : in  std_logic;

    -- To Register File (Decode stage)
    wb_we           : out std_logic;
    wb_addr         : out std_logic_vector(REG_ADDR_W-1 downto 0);
    wb_data         : out std_logic_vector(DATA_WIDTH-1 downto 0)

  );
end writeback;

architecture rtl of writeback is

  signal opcode : std_logic_vector(OPCODE_W-1 downto 0);
  signal wb_mux : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  ------------------------------------------------------------
  -- Extract opcode
  ------------------------------------------------------------
  opcode <= instr_in(31 downto 26);

  ------------------------------------------------------------
  -- Writeback MUX
  -- LW → memory data
  -- Otherwise → ALU result
  ------------------------------------------------------------
  wb_mux <= mem_data_in when opcode = OP_LW
            else alu_data_in;

  ------------------------------------------------------------
  -- Outputs to register file
  ------------------------------------------------------------
  wb_we   <= reg_write_in;
  wb_addr <= rd_in;
  wb_data <= wb_mux;

end rtl;