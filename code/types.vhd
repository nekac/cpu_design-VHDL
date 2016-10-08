library ieee;
use ieee.std_logic_1164.all;

package types is
	constant word_size : positive := 32;
	constant addr_size : positive := 32;
	
	subtype word is std_logic_vector(word_size-1 downto 0);
	subtype addr is std_logic_vector(addr_size-1 downto 0);
	
	type reg_type is record
		num : std_logic_vector(4 downto 0);
		regval : word;
		id_read : std_logic; -- da li id cita taj registar
		hazard_write : std_logic; -- da li hazard ima svez podatak
		ex_write : std_logic; -- da li instrukcija upisuje nesto u rd
		ready : std_logic; -- da li je podatak spreman (uvek je spreman osim kada je LD)
	end record;
	
	type all_regs_types is record
		rd : reg_type;
		rs1 : reg_type;
		rs2 : reg_type;
	end record;
	
	type registers_type is array (0 to 31) of word; --regfile
	
	type instruction_type is record
		PC : addr;
		PC_next : addr;
		jump : std_logic;
		flush : std_logic;
		stop : std_logic;
		registers : all_regs_types;
		opcode : std_logic_vector(5 downto 0);
		imm16 : std_logic_vector(15 downto 0);
		imm11 : std_logic_vector(10 downto 0);
		imm5	: std_logic_vector(4 downto 0);
		datamem_address : addr;
	end record;
	
	type predictor_state is (WEAK_TAKEN, WEAK_NOT_TAKEN, STRONG_TAKEN, STRONG_NOT_TAKEN);
	
	type prediction is record
		addr_from : addr;
		addr_to : addr;
		state : predictor_state;
	end record;
	
	constant stack_size : integer := 16;
	
	type stack_type is array (0 to stack_size - 1) of word;
	
	subtype sp_type is integer range -1 to stack_size - 1;	-- -1 znaci stek je pun
	
	constant predictor_size : integer := 8;
	
	type predictor_cache_type is array (0 to predictor_size - 1) of prediction;
	
	constant memory_size : positive := 2**16;
	
	type memory is array (0 to memory_size - 1) of word;
	
	type dirty is array (0 to memory_size - 1) of std_logic;

end package;