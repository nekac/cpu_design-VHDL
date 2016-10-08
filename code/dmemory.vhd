library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.types.all;

entity dmemory is
	port(
		clk : in std_logic;
		reset : in std_logic;
		addr_in : in addr;
		rd_in : in std_logic; -- citaj iz data mem 
		wr_in : in std_logic; -- upisuj u data mem 
		data_out : out word;
		data_in : in word;
		halt_in : in std_logic
	);
end entity;

architecture dmemory_impl of dmemory is
	signal mem_reg, mem_next : memory;
	signal d_reg, d_next : dirty;
begin
	process(clk, reset) is
	file memfile : text;
	variable inline : line;
	variable address : addr;
	variable data : word;
	begin
		if(reset = '1') then
			
			for i in memory'low to memory'high loop
				mem_reg(i) <= (others => '0');
				d_reg(i) <= '0';
			end loop;
			
			file_open(memfile, "data_in.txt", READ_MODE);
			
			
			loop
				exit when endfile(memfile);
				
				readline(memfile, inline);
				hread(inline, address);
				read(inline, data);
				
				mem_reg(to_integer(unsigned(address))) <= data;
				d_reg(to_integer(unsigned(address))) <= '1';
			end loop;
			
			file_close(memfile);
		elsif(rising_edge(clk)) then
			mem_reg <= mem_next;
			d_reg <= d_next;
		end if;
	end process;
	
	process(mem_reg, addr_in, rd_in, wr_in, data_in) is
	variable dout : word;
	begin
	mem_next <= mem_reg;
	d_next <= d_reg;
	dout := (others => '0');
	
	if (rd_in = '1') then
		dout := mem_reg(to_integer(unsigned(addr_in)));
	end if;
	
	if (wr_in = '1') then
		mem_next(to_integer(unsigned(addr_in))) <= data_in;
		d_next(to_integer(unsigned(addr_in))) <= '1';
	end if;
	
	data_out <= dout;
	
	end process;
	
	process(halt_in) is
	file memfile : text;
	variable inline : line;
	variable outline : line;
	variable address : addr;
	variable data : word;
	begin
	
	if (halt_in = '1') then
		-- poredjenje
		file_open(memfile, "data_exp.txt", READ_MODE);
		loop
			exit when endfile(memfile);
			
			readline(memfile, inline);
			hread(inline, address);
			read(inline, data);
			
			assert(mem_reg(to_integer(unsigned(address))) = data)
				report ("Values do not match!")
					severity warning;
		end loop;
		file_close(memfile);
		
		-- ispis
		file_open(memfile, "data_out.txt", WRITE_MODE);
		
		for i in memory'low to memory'high loop
			if (d_reg(i) = '1') then
				hwrite(outline, std_logic_vector(to_unsigned(i, 32)));
				write(outline, string'(" "));
				write(outline, mem_reg(i));
				writeline(memfile, outline);
			end if;
		end loop;
			
		file_close(memfile);
	end if;
	end process;
	
end architecture;