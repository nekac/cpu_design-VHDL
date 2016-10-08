library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity EX_PHASE is
	port(
		clk : in std_logic;
		reset : in std_logic;
		
		-- komunikacija sa IDom
		instruction_record_in : in instruction_type;
		
		-- komunikacija sa MEMom
		instruction_record_out : out instruction_type;
		
		-- komunikacija sa IFom
		correct_address_out: out addr;
		flush_out : out std_logic;
		
		-- komunikacija sa hazardom
		reg_out : out reg_type
	);
end entity;

architecture EX_IMPL of EX_PHASE is
	signal instruction_record_reg, instruction_record_next : instruction_type;
	signal stack_reg, stack_next : stack_type;
	signal sp_reg, sp_next : sp_type;
begin
	process(clk, reset) is
	begin
		if(reset = '1') then
			sp_reg <= stack_size - 1;
		elsif(rising_edge(clk)) then
			instruction_record_reg <= instruction_record_next;
			stack_reg <= stack_next;
			sp_reg <= sp_next;
		end if;
	end process;
	
	process(instruction_record_in, instruction_record_reg, stack_reg, sp_reg) is
	variable instr_temp : instruction_type;
	variable flush : std_logic;
	variable check_address_range : std_logic_vector(addr_size downto 0); --33b
	variable correct_address : addr;
	variable reg : reg_type;
	variable condition : std_logic;
	begin
		sp_next <= sp_reg;
		stack_next <= stack_reg;
		instr_temp := instruction_record_in;
		flush := '0';
		correct_address := (others => '0');
		condition := '0';
		
		instr_temp.registers.rd.ex_write := '0';
		instr_temp.registers.rd.ready := '0';
		
		if(instr_temp.flush /= '1') then
			case instr_temp.opcode is
				when "000000" => -- LD
					instr_temp.datamem_address := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
															+ to_integer(unsigned(instr_temp.imm16)), addr_size));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '0';
				when "000001" => --ST
					instr_temp.datamem_address := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
															+ to_integer(unsigned(instr_temp.imm16)), addr_size));
				when "000100" => --MOV
					instr_temp.registers.rd.regval := instr_temp.registers.rs1.regval;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "000101" => --MOVI
					-- visih 16b popunjavamo nulama
					instr_temp.registers.rd.regval(31 downto 16) := (others => '0');--(others => imm16(15));
					instr_temp.registers.rd.regval(15 downto 0) := instr_temp.imm16;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "001000" => --ADD
					instr_temp.registers.rd.regval := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
																+ to_integer(unsigned(instr_temp.registers.rs2.regval)), word_size));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "001001" => --SUB
					instr_temp.registers.rd.regval := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
																- to_integer(unsigned(instr_temp.registers.rs2.regval)), word_size));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
					
				when "001100" => --ADDI
					instr_temp.registers.rd.regval := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
																+ to_integer(unsigned(instr_temp.imm16)), word_size));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "001101" => --SUBI
					instr_temp.registers.rd.regval := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
																- to_integer(unsigned(instr_temp.imm16)), word_size));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "010000" => --AND
					instr_temp.registers.rd.regval := instr_temp.registers.rs1.regval and instr_temp.registers.rs2.regval;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "010001" => --OR
					instr_temp.registers.rd.regval := instr_temp.registers.rs1.regval or instr_temp.registers.rs2.regval;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "010010" => --XOR
					instr_temp.registers.rd.regval := instr_temp.registers.rs1.regval xor instr_temp.registers.rs2.regval;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
					
				when "010011" => --NOT
					instr_temp.registers.rd.regval := not instr_temp.registers.rs1.regval;
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "011000" => --SLL
					instr_temp.registers.rd.regval := std_logic_vector(unsigned(instr_temp.registers.rd.regval) sll to_integer(unsigned(instr_temp.imm5)));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "011001" => --SLR
					instr_temp.registers.rd.regval := std_logic_vector(unsigned(instr_temp.registers.rd.regval) srl to_integer(unsigned(instr_temp.imm5)));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "011010" => --SAR
					instr_temp.registers.rd.regval := std_logic_vector(shift_right(unsigned(instr_temp.registers.rd.regval),to_integer(unsigned(instr_temp.imm5))));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
				
				when "011011" => --ROL
					instr_temp.registers.rd.regval := std_logic_vector(unsigned(instr_temp.registers.rd.regval) rol to_integer(unsigned(instr_temp.imm5)));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';
					
				when "011100" => --ROR
					instr_temp.registers.rd.regval := std_logic_vector(unsigned(instr_temp.registers.rd.regval) ror to_integer(unsigned(instr_temp.imm5)));
					instr_temp.registers.rd.ex_write := '1';
					instr_temp.registers.rd.ready := '1';	
				
				when "100000" => --JMP
					if instr_temp.jump /= '1' then
						--javiti ulevo (IF i ID)
						check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
													+ to_integer(signed(instr_temp.imm16)), addr_size + 1));
						correct_address := check_address_range(addr_size - 1 downto 0);
						flush := '1';
						
						if (check_address_range(addr_size) = '1') then
							instr_temp.stop := '1'; --generise izuzetak
						end if;
						
						--javiti udesno (WB, da on javi prediktoru)
						instr_temp.jump := '1';
						instr_temp.PC_next := correct_address;
					end if;
					
				when "100001" => --JSR
					if (sp_reg = -1) then --stek pun
						instr_temp.stop := '1'; --generise izuzetak
					else
						if instr_temp.jump /= '1' then
							--javiti ulevo (IF i ID)
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.registers.rs1.regval)) 
														+ to_integer(signed(instr_temp.imm16)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
							instr_temp.jump := '1';
							instr_temp.PC_next := correct_address;
						end if;
						
						stack_next(sp_reg) <= std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) + 1, addr_size));
						sp_next <= sp_reg - 1;
					end if;
					
				when "100010" => --RTS
					if (sp_reg = stack_size - 1) then --stek prazan
						instr_temp.stop := '1'; --generise izuzetak
					else
						--UVEK lose predvidjanje
						correct_address := stack_reg(sp_reg + 1);
						sp_next <= sp_reg + 1;
						flush := '1';
						--javicemo prediktoru da NEMA skoka
					end if;
					
				when "100100" => --PUSH
					if (sp_reg = -1) then --stek pun
						instr_temp.stop := '1'; --generise izuzetak
					else
						stack_next(sp_reg) <= instr_temp.registers.rs1.regval;
						sp_next <= sp_reg - 1;
					end if;
					
				when "100101" => --POP
					if (sp_reg = stack_size - 1) then --stek prazan
						instr_temp.stop := '1'; --generise izuzetak
					else
						instr_temp.registers.rd.regval := stack_reg(sp_reg + 1);
						sp_next <= sp_reg + 1;
						instr_temp.registers.rd.ex_write := '1';
						instr_temp.registers.rd.ready := '1';
					end if;
				
				when "101000" => --BEQ
					if (instr_temp.registers.rs1.regval = instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when "101001" => --BNQ
					if (instr_temp.registers.rs1.regval /= instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when "101010" => --BGT
					if (instr_temp.registers.rs1.regval > instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when "101011" => --BLT
					if (instr_temp.registers.rs1.regval < instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when "101100" => --BGE
					if (instr_temp.registers.rs1.regval >= instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when "101101" => --BLE
					if (instr_temp.registers.rs1.regval <= instr_temp.registers.rs2.regval) then
						condition := '1';
					else
						condition := '0';
					end if;
					if (instr_temp.jump /= condition) then
						--losa predikcija
						if (condition = '1') then
							--treba da bude skoka, a nije bilo
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC_next)) 
														+ to_integer(signed(instr_temp.imm11)), addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						else
							--ne treba da bude skoka, a bilo je
							check_address_range := std_logic_vector(to_unsigned(to_integer(unsigned(instr_temp.PC)) 
											+ 1, addr_size + 1));
							correct_address := check_address_range(addr_size - 1 downto 0);
							flush := '1';
							if (check_address_range(addr_size) = '1') then
								instr_temp.stop := '1'; --generise izuzetak
							end if;
						end if;
						-- i dalje losa predikcija
						instr_temp.jump := condition;
						instr_temp.PC_next := correct_address;
					end if;
				when others =>
					null;
			end case;
		end if;
		
		reg := instr_temp.registers.rd;
		reg_out <= reg;
		
		correct_address_out <= correct_address;
		flush_out <= flush;
	
		instruction_record_next <= instr_temp;
		instruction_record_out <= instruction_record_reg;
	end process;

end architecture;