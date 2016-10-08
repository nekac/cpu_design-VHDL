library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity predictor is
	port (
		clk : in std_logic;
		reset : in std_logic;
		
	-- komunikacija sa IF
		pc_ifjmp_in : in addr;
		predict_addr_out : out addr;
		predict_flag_out : out std_logic;
		
	-- komunikacija sa WB
		wb_from_in : in addr;
		wb_to_in : in addr;
		wb_flag_in : in std_logic
	);
end entity;

architecture predictor_impl of predictor is
	signal cache_reg, cache_next : predictor_cache_type;
	signal predict_addr_reg, predict_addr_next : addr;
	signal predict_flag_reg, predict_flag_next : std_logic;
begin	
	process(clk, reset) is
	begin
	if (reset = '1') then
		for i in 0 to predictor_size - 1 loop
			cache_reg(i).addr_from <= (others => '0');
			cache_reg(i).addr_to <= (others => '0');
			cache_reg(i).state <= WEAK_NOT_TAKEN;	-- proveriti AOR1 pipeline
		end loop;
	elsif(rising_edge(clk)) then
		cache_reg <= cache_next;
		predict_addr_reg <= predict_addr_next;
		predict_flag_reg <= predict_flag_next;
	end if;
	end process;
	
	process(pc_ifjmp_in, wb_from_in, wb_to_in, wb_flag_in, cache_reg, predict_addr_reg, predict_flag_reg) is
	variable index : integer;
	variable predict_addr_temp : addr;
	variable predict_flag_temp : std_logic;
	begin
	
-- IF
	index := to_integer(unsigned(pc_ifjmp_in(2 downto 0)));
	predict_addr_temp := (others => '0');
	predict_flag_temp := '0';
	
	if (cache_reg(index).addr_from = pc_ifjmp_in) then
		-- ima te adrese
		 predict_addr_temp := cache_reg(index).addr_to;
		 if ((cache_reg(index).state = STRONG_TAKEN) or (cache_reg(index).state = WEAK_TAKEN)) then
			predict_flag_temp := '1';
	    end if;
	end if;
	
-- WB
	cache_next <= cache_reg;
	index := to_integer(unsigned(wb_from_in(2 downto 0)));
	if (cache_reg(index).addr_from = wb_from_in) then
		-- ako se ta adresa vec nalazi u prediktoru
		case cache_reg(index).state is
		
			when STRONG_TAKEN =>
				if (wb_flag_in = '1') then
					cache_next(index).state <= STRONG_TAKEN;
				else
					cache_next(index).state <= WEAK_TAKEN;
				end if;
		
			when WEAK_TAKEN =>
				if (wb_flag_in = '1') then
					cache_next(index).state <= STRONG_TAKEN;
				else
					cache_next(index).state <= STRONG_NOT_TAKEN;
				end if;
						
			when STRONG_NOT_TAKEN =>
				if (wb_flag_in = '1') then
					cache_next(index).state <= WEAK_TAKEN;
				else
					cache_next(index).state <= STRONG_NOT_TAKEN;
				end if;
				
			when WEAK_NOT_TAKEN =>
				if (wb_flag_in = '1') then
					cache_next(index).state <= STRONG_TAKEN;
				else
					cache_next(index).state <= STRONG_NOT_TAKEN;
				end if;
				
			when others => null; 
			
		end case;
	else
		-- ta adresa se NE nalazi
		if (wb_flag_in = '1') then
			-- dodajemo novu adresu u prediktor
			cache_next(index).addr_from <= wb_from_in;
			cache_next(index).addr_to <= wb_to_in;
			cache_next(index).state <= STRONG_TAKEN;
		end if;
	end if;
	
	predict_addr_next <= predict_addr_temp;
	predict_flag_next <= predict_flag_temp;
	predict_addr_out <= predict_addr_reg;
	predict_flag_out <= predict_flag_reg;
	
	end process;

end architecture;