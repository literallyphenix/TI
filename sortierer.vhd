library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sortierer is
	generic (
		CNT_OFL : positive := 50000000 ; -- Sekundentakt Überlauf (overflow)
		TIME_WEG_MAX : positive := 5 ; -- maximale Werkstück-Durchlaufzeit auf langem Weg (bei geöffneter Schranke)
		FWD : std_logic := '0';
		BCK : std_logic := '1';
		RUN : std_logic := '1';
		STP : std_logic := '0';
		WEG_K : std_logic := '0';
		WEG_M : std_logic := '1'
	);

	port (
		reset : in std_logic; -- Key0
		clk   : in std_logic; --50 MHz
		oe_in : in std_logic; -- Switch 9
		opt_sens : in std_logic; -- optischer Sensor
		ind_sens : in std_logic; -- induktiv Sensor
		oe_n_out : out std_logic;
		weiche_out : out std_logic; -- Weg A / Weg B -Umschaltung
		motor_pwr_out : out std_logic; -- ...
		motor_dir_out : out std_logic -- Motor Drehrichtung
	);
end entity sortierer;

architecture arch of sortierer is

-- signals
	 signal cnt : unsigned(25 downto 0) := (others => '0');
    signal time_s : unsigned(4 downto 0) := (others => '0');
    signal weiche : std_logic := WEG_K;
    signal motor_pwr : std_logic := '0'; -- Default motor power is off
    signal motor_dir : std_logic := FWD; -- Default motor direction is forward

	type main_state_t is (idle, move, mweg);

	signal main_state, next_main_state : main_state_t;

begin

    sort_control : process(clk, reset) is
    begin
        if (reset = '1') then
            -- Reset conditions
            motor_pwr <= RUN;
            weiche <= WEG_K;
            main_state <= idle;
            time_s <= (others => '0');
        elsif rising_edge(clk) then
            -- Increment time counter
            if main_state /= idle then
                if cnt = CNT_OFL - 1 then
                    cnt <= (others => '0');
                    time_s <= time_s + 1;
                else
                    cnt <= cnt + 1;
                end if;
            end if;

            -- State transition logic
            case main_state is
                when idle =>
                    if opt_sens = '1' then
                        next_main_state <= move;
                    else
                        next_main_state <= idle;
                    end if;

                when move =>
                    if ind_sens = '1' then -- Workpiece detected as metal
                        weiche <= WEG_M; -- Move the metal workpiece to path M
                    else
                        weiche <= WEG_K; -- Move the plastic workpiece to path K
                    end if;

                    if time_s = TIME_WEG_MAX then
                        next_main_state <= idle;
                    else
                        next_main_state <= mweg;
                    end if;

                when mweg =>
                    if time_s = TIME_WEG_MAX then
                        next_main_state <= idle;
                    else
                        next_main_state <= mweg;
                    end if;
            end case;
        end if;

        -- Output assignments
        oe_n_out <= not oe_in; -- Voltage translator active
        weiche_out <= weiche;
        motor_pwr_out <= motor_pwr;
        motor_dir_out <= motor_dir;

        -- State transition update
        main_state <= next_main_state;
    end process sort_control;

end architecture arch;