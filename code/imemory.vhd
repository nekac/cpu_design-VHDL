library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.types.all;

entity imemory is
	port(
		reset : in std_logic;
		addr_in : in addr;
		word_out : out word
	);
end entity;

architecture imemory_impl of imemory is
	signal mem : memory;
begin
	process(reset) is
	file memfile : text;
	variable inline : line;
	variable address : addr;
	variable instruction : word;
	begin
		if(reset = '1') then
			
			for i in memory'low to memory'high loop
				mem(i) <= (others => '1');
			end loop;
			
			file_open(memfile, "inst_in.txt", READ_MODE);
			
			
			loop
				exit when endfile(memfile);
				
				readline(memfile, inline);
				hread(inline, address);
				read(inline, instruction);
				
				mem(to_integer(unsigned(address))) <= instruction;
			end loop;
			
			file_close(memfile);
		end if;
	end process;
	
	word_out <= mem(to_integer(unsigned(addr_in)));
	
end architecture;