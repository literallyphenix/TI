library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity taktteiler is
   port( 
		clk : in std_logic; --Ein Eingang für das Taktsignal 50MHz
      clk_10Hz : out std_logic--Ein Ausgang für ein Signal mit 10 Hz
	);

end entity taktteiler;

architecture ARCH of taktteiler is

signal Q_int   : std_logic;
signal counter : unsigned (22 downto 0);

begin
	P: process (clk)
	begin

		if(clk='1' and clk'event) then
			counter<= counter+1;
			
			if counter= 5_000_000 - 1 then
				counter <= (others =>'0');
				Q_int<= not(Q_int);

			end if ;
		end if ;
	end process P;
	clk_10Hz <= Q_int;--Ausgangssignal clk_10Hz zugewiesen
end architecture ARCH ;