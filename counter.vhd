library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity versuch2b is
	port (
			reset_n  	: in std_logic; -- Key 3
			clk      	: in std_logic; --50 MHz
			switches 	: in std_logic_vector(7 downto 0); -- zur Übernahme des ofl-values
			cnt_enable	: in std_logic; -- SW9
			ofl_rd 		: in std_logic; -- read and store ofl-value, KEY0
			cnt_rd 		: in std_logic; -- read and store the actual count-value, KEY1
			cnt_val_act : out std_logic_vector(7 downto 0); -- aktueller Zählwert
			cnt_val_stored_out : out std_logic_vector(7 downto 0) -- gespeicherter Zählwert
	);
end entity versuch2b;
 
architecture arch of versuch2b is                                      --zurückgezetzt mit 0
	signal count_value    : unsigned(7 downto 0) := (others => '0'); -- 8-Bit-Vorzeichenlose Zahl, repräsentiert den aktuellen Zählwert
	signal overflow_val   : unsigned(7 downto 0) := (others => '0'); -- 8-Bit-Vorzeichenlose Zahl, repräsentiert den Überlaufwert Gespeicherter Zählwert
	signal counter : integer range 0 to 4999999 := 0;
begin

	process(clk, reset_n)
	begin
		--<key3>--
		if reset_n = '1' then
			count_value <= (others => '0');
			elsif rising_edge(clk) then
			--<key0>--
				if ofl_rd = '1' then
					overflow_val <= unsigned(switches);
				end if;
			counter <= counter + 1;
			if counter = 4999999 then
			counter <= 0;
				--<sw9>--
				if cnt_enable = '1' then
					if count_value >= overflow_val then
						count_value <= (others => '0');
					else
				count_value <= count_value + 1;
					end if;
				end if;
				--<key1>--
				if cnt_rd = '1' then
					cnt_val_stored_out <= not std_logic_vector(count_value);
				end if;
			end if;

		end if;

end process;
	cnt_val_act <= not std_logic_vector( count_value );
end architecture arch;