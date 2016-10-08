library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.types.all;

entity IF_PHASE is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
	-- kominikacija sa prediktorom
		pc_ifjmp_out : out addr;
		predict_addr_in : in addr;
		predict_flag_in : in std_logic;
		
	-- komunikacija sa ID-om
		instruction_record_out : out instruction_type;
		
	-- komunikacija sa EX-om
		correct_address_in : in addr;
		flush_in : in std_logic;
		
	-- komunikacija sa hazardom
		stall_in : in std_logic
	);
end entity;

architecture IF_IMPL of IF_PHASE is
	signal PC_reg, PC_next : addr;
	signal instruction_record_reg, instruction_record_next : instruction_type;
begin
	process(clk, reset) is
	file memfile : text;
	variable inline : line;
	variable address : addr;
	begin
		if(reset = '1') then
			file_open(memfile, "inst_in.txt", READ_MODE);
			
			readline(memfile, inline);
			hread(inline, address);
			pc_reg <= address;
			
			file_close(memfile);
		elsif(rising_edge(clk)) then
			PC_reg <= PC_next;
			instruction_record_reg <= instruction_record_next;
		end if;
	end process;
	
	process(predict_addr_in, predict_flag_in, correct_address_in, flush_in, stall_in, PC_reg, instruction_record_reg) is
	variable PC_temp : addr;
	variable instruction_record_temp : instruction_type;
	begin
		PC_temp := PC_reg;
		instruction_record_temp := instruction_record_reg;
		
		instruction_record_temp.flush := '0';
		if(stall_in = '1') then
			instruction_record_temp.flush := '1';
		else
			if(flush_in = '1') then
				PC_temp := correct_address_in;
				instruction_record_temp.flush := '1';
			elsif(predict_flag_in = '1') then
				PC_temp := predict_addr_in;
			else
				PC_temp := std_logic_vector(to_unsigned(to_integer(unsigned(PC_reg)) + 1, addr_size)); -- pc_temp := pc_reg+1
			end if;
		end if;
		
		instruction_record_temp.PC := PC_reg;
		instruction_record_temp.jump := predict_flag_in;
		instruction_record_temp.PC_next := PC_temp;
		
		instruction_record_out <= instruction_record_temp;
		pc_ifjmp_out <= PC_temp;
		
		PC_next <= PC_temp;
		instruction_record_next <= instruction_record_temp;
	end process;

end architecture;

