library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Project is
end entity;

architecture i of Project is
	signal clk : std_logic;
	signal reset : std_logic;
	
	-- komunikacija sa instrukcijskom memorijom
	signal instr_mem_addr : addr;
	signal instr_mem_word : word;
	
	-- komunikacija sa data memorijom
	signal data_mem_addr : addr;
	signal data_mem_rd : std_logic;
	signal data_mem_wr : std_logic;
	signal data_mem_word_out : word;	-- u odnosu na CPU
	signal data_mem_word_in : word;
	signal halt : std_logic;
	
begin
	cpu : entity work.CPU port map(
		clk_in => clk,
		reset_in => reset,
		
		-- komunikacija sa instrukcijskom memorijom
		instr_mem_addr_out => instr_mem_addr,
		instr_mem_word_in => instr_mem_word,
		
		-- komunikacija sa data memorijom
		data_mem_addr_out => data_mem_addr,
		data_mem_rd_out => data_mem_rd,
		data_mem_wr_out => data_mem_wr,
		data_mem_word_out => data_mem_word_out,
		data_mem_word_in => data_mem_word_in,
		halt_out => halt
	);
	
	imem : entity work.imemory port map(
		reset => reset,
		addr_in => instr_mem_addr,
		word_out => instr_mem_word
	);
	
	dmem : entity work.dmemory port map(
		clk => clk,
		reset => reset,
		addr_in => data_mem_addr,
		rd_in => data_mem_rd,
		wr_in => data_mem_wr,
		data_out => data_mem_word_in,
		data_in => data_mem_word_out,
		halt_in => halt
	);
	
	process is
	begin
	clk <= '0';
	reset <= '1';
	wait for 100ns;
	reset <= '0';
	
	loop
		clk <= not clk;
		wait for 5ns;
	end loop;
	end process;
end architecture;