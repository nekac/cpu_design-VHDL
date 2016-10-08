library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity CPU is
	port(
		clk_in : in std_logic;
		reset_in : in std_logic;
		
		-- komunikacija sa instrukcijskom memorijom
		instr_mem_addr_out : out addr;
		instr_mem_word_in : in word;
		
		-- komunikacija sa data memorijom
		data_mem_addr_out : out addr;
		data_mem_rd_out : out std_logic;
		data_mem_wr_out : out std_logic;
		data_mem_word_out : out word;
		data_mem_word_in : in word;
		halt_out : out std_logic
	);
end entity;

architecture CPU_impl of CPU is
	signal clk : std_logic; -- all from outside CPU
	signal reset : std_logic; -- all from outside CPU
	signal stop : std_logic; -- WB & CPU
	
	-- IF & Predictor
	signal pc_ifjmp : addr;
	signal predict_addr : addr;
	signal predict_flag : std_logic;
	
	-- IF & ID 
	signal if2id : instruction_type; -- + (ID & IF)
	
	-- IF & EX 
	signal correct_address : addr; -- + (EX & IF)
	signal flush : std_logic; -- + (ID & EX), (EX & IF)
	
	-- IF & hazard
	signal stall : std_logic; -- + (ID & hazard)
	
	-- ID & EX 
	signal id2ex : instruction_type; -- + (EX & ID)

	-- ID & regfile
	signal reg_num_id : all_regs_types; -- + (ID & hazard)
	signal reg_val_id : all_regs_types;
	
	-- ID & hazard
	signal haz_val : all_regs_types;
	
	-- EX & MEM 
	signal ex2mem : instruction_type; -- + (MEM & EX)
	
	-- EX & hazard
	signal reg_ex : reg_type;
	
	-- MEM & WB
	signal mem2wb : instruction_type; -- + (WB & MEM)
	
	-- MEM & hazard
	signal reg_mem : reg_type;
	
	-- WB & hazard
	signal reg_wb : reg_type;
	
	-- WB & regfile
	signal reg_wb_file : reg_type;
	
	-- WB & Predictor
	signal addr_from : addr;
	signal addr_to : addr;
	signal branch : std_logic;

	
begin
	if_phase : entity work.IF_PHASE port map(
		clk => clk,
		reset => reset,
		pc_ifjmp_out => pc_ifjmp,
		predict_addr_in => predict_addr,
		predict_flag_in => predict_flag,
		instruction_record_out => if2id,
		correct_address_in => correct_address,
		flush_in => flush,
		stall_in => stall
	);
	
	id_phase : entity work.ID_PHASE port map(
		clk => clk,
		reset => reset,
		instruction_record_in => if2id,
		pc_out => instr_mem_addr_out,
		word_in => instr_mem_word_in,
		instruction_record_out => id2ex,
		flush_in => flush,
		reg_nums_out => reg_num_id,
		reg_vals_in => reg_val_id,
		hazard_values_in => haz_val, 
		stall_in => stall
	);
	
	ex_phase : entity work.EX_PHASE port map(
		clk => clk,
		reset => reset,
		instruction_record_in => id2ex,
		instruction_record_out => ex2mem,
		correct_address_out => correct_address,
		flush_out => flush,
		reg_out => reg_ex
	);
	
	mem_phase : entity work.MEM_PHASE port map(
		clk => clk,
		reset => reset,
		instruction_record_in => ex2mem,
		addr_out => data_mem_addr_out,
		rd_out => data_mem_rd_out,
		data_in => data_mem_word_in,
		wr_out => data_mem_wr_out,
		data_out => data_mem_word_out,
		instruction_record_out => mem2wb,
		reg_out => reg_mem
	);
	
	wb_phase : entity work.WB_PHASE port map(
		clk => clk,
		reset => reset,
		stop_out => stop,
		instruction_record_in => mem2wb,
		reg_file_out => reg_wb_file,
		addr_from_out => addr_from,
		addr_to_out => addr_to,
		branch_out => branch,
		reg_out => reg_wb
	);
	
	hazard : entity work.hazard port map(
		id_reg_nums_in => reg_num_id,
		hazard_values_out => haz_val, 
		stall_out => stall,
		ex_reg_in => reg_ex,
		mem_reg_in => reg_mem,
		wb_reg_in => reg_wb
	);
	
	predictor : entity work.predictor port map(
		clk => clk,
		reset => reset,
		pc_ifjmp_in => pc_ifjmp,
		predict_addr_out => predict_addr,
		predict_flag_out => predict_flag,
		wb_from_in => addr_from,
		wb_to_in => addr_to,
		wb_flag_in => branch
	);
	
	regfile : entity work.regfile port map(
		clk => clk,
		reset => reset,
		reg_nums_in => reg_num_id,
		reg_vals_out => reg_val_id,
		reg_vals_in => reg_wb_file
	);

	halt_out <= stop;
	clk <= clk_in when stop /= '1' else '0';
	reset <= reset_in;
end architecture;
