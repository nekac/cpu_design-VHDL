library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity WB_PHASE is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
		-- ka samom procesoru
		stop_out : out std_logic;
		
		-- komunikacija sa MEMom
		instruction_record_in : in instruction_type;
		
		-- komunikacija sa registarskim fajlom
		reg_file_out : out reg_type;
		
		-- komunikacija sa prediktorom
		addr_from_out : out addr;
		addr_to_out : out addr;
		branch_out : out std_logic;
		
		-- komunikacija sa hazardom
		reg_out : out reg_type
	);
end entity;

architecture WB_IMPL of WB_PHASE is
signal instruction_record_reg, instruction_record_next : instruction_type;
begin
	process(clk, reset) is
	begin
		if(reset = '1') then
			null;
		elsif(rising_edge(clk)) then
			instruction_record_reg <= instruction_record_next;
		end if;
	end process;
	
	process(instruction_record_in, instruction_record_reg) is
	variable instr_temp : instruction_type;
	variable addr_from : addr;
	variable addr_to : addr;
	variable branch : std_logic;
	variable stop : std_logic;
	begin
		instr_temp := instruction_record_reg;
		instr_temp := instruction_record_in;
		addr_from := (others => '0');
		addr_to := (others => '0');
		branch := '0';
		stop := '0';
		if(instr_temp.flush /= '1') then
			stop := instr_temp.stop;
			addr_from := instr_temp.PC;
			addr_to := instr_temp.PC_next;
			branch := instr_temp.jump;
		else	
			instr_temp.registers.rd.ex_write := '0';
		end if;
		
		stop_out <= stop;
		reg_file_out <= instr_temp.registers.rd;
		addr_from_out <= addr_from;
		addr_to_out <= addr_to;
		branch_out <= branch;
		instruction_record_next <= instr_temp;
		reg_out <= instr_temp.registers.rd;
	end process;

end architecture;