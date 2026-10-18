library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity calendar is
    Port (
        CLK   : in  STD_LOGIC;
        RST   : in  STD_LOGIC;
        Hours : out STD_LOGIC_VECTOR(5 downto 0);
        Mins  : out STD_LOGIC_VECTOR(5 downto 0);
        Secs  : out STD_LOGIC_VECTOR(5 downto 0)
    );
end calendar;

architecture Behavioral of calendar is
    signal sec_cnt  : unsigned(5 downto 0) := (others => '0');
    signal min_cnt  : unsigned(5 downto 0) := (others => '0');
    signal hour_cnt : unsigned(5 downto 0) := (others => '0');
begin

    process(CLK, RST)
    begin
        if RST = '1' then
            sec_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            if sec_cnt = 59 then
                sec_cnt <= (others => '0');
            else
                sec_cnt <= sec_cnt + 1;
            end if;
        end if;
    end process;

    process(CLK, RST)
    begin
        if RST = '1' then
            min_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            if min_cnt = 59 and sec_cnt = 59 then
                min_cnt <= (others => '0');
            elsif sec_cnt = 59 then
                min_cnt <= min_cnt + 1;
            else
                min_cnt <= min_cnt;
            end if;
        end if;
    end process;

    process(CLK, RST)
    begin
        if RST = '1' then
            hour_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            if hour_cnt = 23 and min_cnt = 59 and sec_cnt = 59 then
                hour_cnt <= (others => '0');
            elsif min_cnt = 59 and sec_cnt = 59 then
                hour_cnt <= hour_cnt + 1;
            else
                hour_cnt <= hour_cnt;
            end if;
        end if;
    end process;

    Hours <= std_logic_vector(hour_cnt);
    Mins  <= std_logic_vector(min_cnt);
    Secs  <= std_logic_vector(sec_cnt);

end Behavioral;
