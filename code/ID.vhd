library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ID_PHASE is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
	-- komunikacija sa IF-om
		instruction_record_in : in instruction_type;
		
	-- komunikacija sa instrukcijskom memorijom
		pc_out : out addr;
		word_in : in word;
		
	-- komunikacija sa EX-om
		instruction_record_out : out instruction_type;
		flush_in : in std_logic;
		
	-- komunikacija sa registarskim fajlom
		reg_nums_out : out all_regs_types;
		reg_vals_in : in all_regs_types;
		
	-- komunikacija sa hazard kontrolorom
		hazard_values_in : in all_regs_types;
		stall_in : in std_logic
	);
end entity;

architecture ID_IMPL of ID_PHASE is
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
	
	process(instruction_record_in, word_in, flush_in, reg_vals_in, hazard_values_in, stall_in, instruction_record_reg) is
	variable instr_temp : instruction_type;
	variable word_tmp : word;
	begin
		instr_temp := instruction_record_in;
		
		pc_out <= instr_temp.PC;	-- pitamo memoriju
		word_tmp := word_in;			-- memorija nam vraca rec
		
		instr_temp.opcode := word_tmp(31 downto 26);
		
		case (instr_temp.opcode) is
		
	-- Instrukcije citanja iz memorije i smestanja u memoriju
	
			when "000000" => -- LOAD
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.imm16 := word_tmp(15 downto 0);
			
			when "000001" => -- STORE
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm16(15 downto 11) := word_tmp(25 downto 21);
				instr_temp.imm16(10 downto 0) := word_tmp(10 downto 0);
			
	-- Aritmeticke i logicke instrukcije
	
			when "001100" => -- ADDI
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.imm16 := word_tmp(15 downto 0);
				
			when "001000" => -- ADD
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
			
			when "001101" => -- SUBI
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.imm16 := word_tmp(15 downto 0);
		
			when "001001" => -- SUB
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				
			when "010000" => -- AND
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
			
			when "010001" => -- OR
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
			
			when "010010" => -- XOR
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
			
			when "010011" => -- NOT
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
		
	-- Pomeracke instrukcije	
		
			when "011000" => -- SHL
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm5 := word_tmp(15 downto 11);
				instr_temp.registers.rd.id_read := '1'; -- zelim da citam rd
			
			when "011001" => -- SHR
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm5 := word_tmp(15 downto 11);
				instr_temp.registers.rd.id_read := '1'; -- zelim da citam rd
				
			when "011010" => -- SAR
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm5 := word_tmp(15 downto 11);
				instr_temp.registers.rd.id_read := '1'; -- zelim da citam rd
				
			when "011011" => -- ROL
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm5 := word_tmp(15 downto 11);
				instr_temp.registers.rd.id_read := '1'; -- zelim da citam rd
				
			when "011100" => -- ROR
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm5 := word_tmp(15 downto 11);
				instr_temp.registers.rd.id_read := '1'; -- zelim da citam rd
		
	-- Instrukcije premestanja
	
			when "000100" => -- MOV
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				
			when "000101" => -- MOVI
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
				instr_temp.imm16 := word_tmp(15 downto 0);
				
	-- Instrukcije bezuslovnog skoka
	
			when "100000" => -- JMP
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.imm16 := word_tmp(15 downto 0);
				
			when "100001" => -- JSR
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.imm16 := word_tmp(15 downto 0);
				
			when "100010" => -- RTS
				null;
	-- Instrukcije uslovnog skoka
			
			when "101000" => -- BEQ
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
			when "101001" => -- BNQ
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
			when "101010" => -- BLT
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
			when "101011" => -- BGT
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
			when "101100" => -- BLE
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
			when "101101" => -- BGE
				instr_temp.imm5 := word_tmp(25 downto 21);
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
				instr_temp.registers.rs2.num := word_tmp(15 downto 11);
				instr_temp.registers.rs2.id_read := '1'; -- zelim da citam rs2
				instr_temp.imm11 := word_tmp(10 downto 0);
			
		-- Instrukcija HALT
			
			when "111111" => -- HALT
				instr_temp.stop := '1';
		-- Instrukcije za rad sa stekom
			
			when "100101" => -- POP 
				instr_temp.registers.rd.num := word_tmp(25 downto 21);
			
			when "100100" => -- PUSH
				instr_temp.registers.rs1.num := word_tmp(20 downto 16);
				instr_temp.registers.rs1.id_read := '1'; -- zelim da citam rs1
			
			when others =>
					instr_temp.stop := '1';
		end case;
		
		reg_nums_out <= instr_temp.registers;		-- saljemo registarskom fajlu i hazardu brojeve registara
		
		if(flush_in = '1') then
			instr_temp.flush := '1';
		end if;
		
		if(stall_in = '1') then
			instr_temp := instruction_record_reg;
			instr_temp.flush := '1';
		elsif(instr_temp.flush /= '1') then
			if(instr_temp.registers.rd.id_read = '1') then		-- ako citamo rd
				if(hazard_values_in.rd.hazard_write = '1') then	
					instr_temp.registers.rd.regval := hazard_values_in.rd.regval;	-- uzima vrednost od hazarda
				else
					instr_temp.registers.rd.regval := reg_vals_in.rd.regval; 	-- uzima vrednost od reg fajla
				end if;
			end if;
			if(instr_temp.registers.rs1.id_read = '1') then		-- ako citamo rs1
				if(hazard_values_in.rs1.hazard_write = '1') then	
					instr_temp.registers.rs1.regval := hazard_values_in.rs1.regval;	-- uzima vrednost od hazarda
				else
					instr_temp.registers.rs1.regval := reg_vals_in.rs1.regval; 	-- uzima vrednost od reg fajla
				end if;
			end if;
			if(instr_temp.registers.rs2.id_read = '1') then		-- ako citamo rs2
				if(hazard_values_in.rs2.hazard_write = '1') then	
					instr_temp.registers.rs2.regval := hazard_values_in.rs2.regval;	-- uzima vrednost od hazarda
				else
					instr_temp.registers.rs2.regval := reg_vals_in.rs2.regval; 	-- uzima vrednost od reg fajla
				end if;
			end if;
		end if;
		
		
		instruction_record_next <= instr_temp;
		instruction_record_out <= instruction_record_reg;
		
	end process;

end architecture;
