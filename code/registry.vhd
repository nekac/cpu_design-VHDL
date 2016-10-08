library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity regfile is
	port (
		clk : in std_logic;
		reset : in std_logic;
		
	-- komunikacija sa ID
		reg_nums_in : in all_regs_types;
		reg_vals_out : out all_regs_types; 
		
	-- komunikacija sa WB
		reg_vals_in : in reg_type 
	);
end entity;

architecture reg_impl of regfile is
	signal reg_reg, reg_next : registers_type;
begin
	process(clk, reset) is
	begin
	if (reset = '1') then
		for i in 0 to 31 loop
			reg_reg(i) <= (others => '0');
		end loop;
	elsif(rising_edge(clk)) then
		reg_reg <= reg_next;
	end if;
	end process;
	
	process(reg_nums_in, reg_vals_in, reg_reg) is
	begin
		reg_next <= reg_reg;
		
	-- ID
		reg_vals_out <= reg_nums_in;
		reg_vals_out.rd.regval <= reg_reg(to_integer(unsigned(reg_nums_in.rd.num)));
	-- vrednost rd = reg_reg ( broj registra koji id salje).vrednost
		reg_vals_out.rs1.regval <= reg_reg(to_integer(unsigned(reg_nums_in.rs1.num)));
		reg_vals_out.rs2.regval <= reg_reg(to_integer(unsigned(reg_nums_in.rs2.num)));
		
	-- WB
		if reg_vals_in.ex_write = '1' then
		-- ako WB salje svezu vrednost registra, tj. ako je bilo upisa
			reg_next(to_integer(unsigned(reg_vals_in.num))) <= reg_vals_in.regval;
		-- reg_next ( broj registra rd koji WB salje) = (vrednost registra koju WB salje)
		end if;
		
	end process;
end architecture;