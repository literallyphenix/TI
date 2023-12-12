library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sortierer is
    generic (
        CNT_OFL : positive := 50_000_000; -- Sekundentakt overflow 
        TIME_WEG_K : positive := 50_000_000; -- Kunststoff-Werkstück
        TIME_WEG_M : positive := 25_000_000; -- Metall-Werkstück
        FWD : std_logic := '0';
        BCK : std_logic := '1';
        RUN : std_logic := '1';
        STP : std_logic := '0';
        WEG_K : std_logic := '0';
        WEG_M : std_logic := '1'
    );
    port (
        reset_n : in std_logic; -- Key3
        clk : in std_logic; -- 50 MHz clock
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
    signal weiche : std_logic := '0';
    signal motor_pwr : std_logic := '0';
    signal motor_dir : std_logic := '0';
    type main_state_t is (idle, sensor_check, metall_kunststoff_check, weiche_set, transporting);
    signal main_state, next_main_state : main_state_t := idle;

begin
    sort_control : process(clk, reset_n) is
    begin
        if (reset_n = '0') then
            -- Initialization on reset
            cnt <= (others => '0');
            time_s <= (others => '0');
            main_state <= idle;
            next_main_state <= idle;
            
        elsif rising_edge(clk) then
            main_state <= next_main_state; -- z_reg
            
            -- fast counter, overflow = 1s
            if cnt = to_unsigned(CNT_OFL, cnt'length) or main_state = idle then
                cnt <= (others => '0');
            else
                cnt <= cnt + 1;
            end if;
            
            -- Sekunden timer
            if main_state = idle then -- reset timer
                time_s <= (others => '0');
            elsif cnt = CNT_OFL then
                time_s <= time_s + 1;
            end if;
            
            case main_state is
                when idle =>
                    if opt_sens = '1' then
                        next_main_state <= sensor_check;
                    else
                        next_main_state <= idle;
                    end if;
                    
                when sensor_check =>
                    if opt_sens = '1' then
                        motor_pwr <= RUN;
                        motor_dir <= FWD;
                        next_main_state <= metall_kunststoff_check;
                    else
                        motor_pwr <= STP;
                        motor_dir <= FWD;
                        next_main_state <= idle;
                    end if;
                    
                when metall_kunststoff_check =>
                    if ind_sens = '1' then
                        weiche <= WEG_M;
                        next_main_state <= weiche_set;
                    else
                        weiche <= WEG_K;
                        next_main_state <= weiche_set;
                    end if;
                    
                when weiche_set =>
                    if time_s = to_unsigned(TIME_WEG_K, time_s'length) then
                        motor_pwr <= STP;
                        weiche <= '0';
                        next_main_state <= idle;
                    else
                        motor_pwr <= RUN;
                        next_main_state <= transporting;
                    end if;
                    
                when transporting =>
                    if time_s = to_unsigned(TIME_WEG_K, time_s'length) then
                        motor_pwr <= STP;
                        next_main_state <= idle;
                    else
                        motor_pwr <= RUN;
                    end if;
            end case;
        end if;
        
        oe_n_out <= not oe_in; -- voltage translator active
        weiche_out <= weiche;
        motor_pwr_out <= motor_pwr;
        motor_dir_out <= motor_dir;
    end process sort_control;
end architecture arch;
