library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity MEM_PHASE is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
		-- komunikacija sa EXom
		instruction_record_in : in instruction_type;
		
		-- komunikacija sa data memorijom
		addr_out : out addr;
		rd_out : out std_logic;
		data_in : in word;
		wr_out : out std_logic;
		data_out : out word;
		
		-- komunikacija sa WBom
		instruction_record_out : out instruction_type;
		
		-- komunikacija sa hazardom
		reg_out : out reg_type
	);
end entity;

architecture MEM_IMPL of MEM_PHASE is
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
	
	process(instruction_record_in, data_in, instruction_record_reg) is
	variable rd : std_logic;
	variable wr : std_logic;
	variable data : word;
	variable instr_temp : instruction_type;
	begin
		instr_temp := instruction_record_in;
		rd := '0';
		wr := '0';
		data := (others => '0');
		addr_out <= instr_temp.datamem_address;
		if(instr_temp.flush /= '1') then
			case instr_temp.opcode is
				when "000000" => -- LD
					rd := '1';
					instr_temp.registers.rd.regval := data_in;
					instr_temp.registers.rd.ready := '1';
				when "000001" => -- STORE
					wr := '1';
					data := instr_temp.registers.rs2.regval;
				when others =>
					null;
			end case;
		end if;
		rd_out <= rd;
		wr_out <= wr;
		data_out <= data;
		instruction_record_next <= instr_temp;
		instruction_record_out <= instruction_record_reg;
		reg_out <= instr_temp.registers.rd;
	end process;

end architecture;