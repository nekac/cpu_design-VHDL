library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity hazard is
	port(
		-- komunikacija sa IDom
		id_reg_nums_in : in all_regs_types;
		hazard_values_out : out all_regs_types;
		stall_out : out std_logic;
		
		-- komunikacija sa EXom
		ex_reg_in : in reg_type;
		
		-- komunikacija sa MEMom
		mem_reg_in : in reg_type;
		
		-- komunikacija sa WBom
		wb_reg_in : in reg_type
		
	);
end entity;

architecture hazard_impl of hazard is
begin
	process(id_reg_nums_in, ex_reg_in, mem_reg_in, wb_reg_in) is
	variable stall : std_logic;
	variable hazard_values : all_regs_types;
	begin
		stall := '0';
		hazard_values := id_reg_nums_in;
		
		-- rd
		if(id_reg_nums_in.rd.id_read = '1') then -- ako ID cita taj registar
			if(id_reg_nums_in.rd.num = ex_reg_in.num and ex_reg_in.ex_write = '1') then -- proveravanje sa ex-om
				if(ex_reg_in.ready = '1') then
					hazard_values.rd.regval := ex_reg_in.regval;
					hazard_values.rd.hazard_write := '1';
				else
					stall := '1';
				end if;
				
			elsif(id_reg_nums_in.rd.num = mem_reg_in.num and mem_reg_in.ex_write = '1') then -- proveravanje sa mem-om
				hazard_values.rd.regval := mem_reg_in.regval;
				hazard_values.rd.hazard_write := '1';
				
			elsif(id_reg_nums_in.rd.num = wb_reg_in.num and wb_reg_in.ex_write = '1') then -- proveravanje sa wb-om
				hazard_values.rd.regval := wb_reg_in.regval;
				hazard_values.rd.hazard_write := '1';
			end if;
		end if;
		
		-- rs1
		if(id_reg_nums_in.rs1.id_read = '1') then -- ako ID cita taj registar
			if(id_reg_nums_in.rs1.num = ex_reg_in.num and ex_reg_in.ex_write = '1') then -- proveravanje sa ex-om
				if(ex_reg_in.ready = '1') then
					hazard_values.rs1.regval := ex_reg_in.regval;
					hazard_values.rs1.hazard_write := '1';
				else
					stall := '1';
				end if;
				
			elsif(id_reg_nums_in.rs1.num = mem_reg_in.num and mem_reg_in.ex_write = '1') then -- proveravanje sa mem-om
				hazard_values.rs1.regval := mem_reg_in.regval;
				hazard_values.rs1.hazard_write := '1';
				
			elsif(id_reg_nums_in.rs1.num = wb_reg_in.num and wb_reg_in.ex_write = '1') then -- proveravanje sa wb-om
				hazard_values.rs1.regval := wb_reg_in.regval;
				hazard_values.rs1.hazard_write := '1';
			end if;
		end if;
		
		-- rs2
		if(id_reg_nums_in.rs2.id_read = '1') then -- ako ID cita taj registar
			if(id_reg_nums_in.rs2.num = ex_reg_in.num and ex_reg_in.ex_write = '1') then -- proveravanje sa ex-om
				if(ex_reg_in.ready = '1') then
					hazard_values.rs2.regval := ex_reg_in.regval;
					hazard_values.rs2.hazard_write := '1';
				else
					stall := '1';
				end if;
				
			elsif(id_reg_nums_in.rs2.num = mem_reg_in.num and mem_reg_in.ex_write = '1') then -- proveravanje sa mem-om
				hazard_values.rs2.regval := mem_reg_in.regval;
				hazard_values.rs2.hazard_write := '1';
				
			elsif(id_reg_nums_in.rs2.num = wb_reg_in.num and wb_reg_in.ex_write = '1') then -- proveravanje sa wb-om
				hazard_values.rs2.regval := wb_reg_in.regval;
				hazard_values.rs2.hazard_write := '1';
			end if;
		end if;
		
		
		hazard_values_out <= hazard_values;
		stall_out <= stall;
	end process;
end architecture;