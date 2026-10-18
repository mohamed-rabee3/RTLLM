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
    signal s_secs  : unsigned(5 downto 0) := (others => '0');
    signal s_mins  : unsigned(5 downto 0) := (others => '0');
    signal s_hours : unsigned(5 downto 0) := (others => '0');
begin

    -- Seconds process
    process(CLK, RST)
    begin
        if RST = '1' then
            s_secs <= (others => '0');
        elsif rising_edge(CLK) then
            if s_secs = 59 then
                s_secs <= (others => '0');
            else
                s_secs <= s_secs + 1;
            end if;
        end if;
    end process;

    -- Minutes process
    process(CLK, RST)
    begin
        if RST = '1' then
            s_mins <= (others => '0');
        elsif rising_edge(CLK) then
            if (s_mins = 59) and (s_secs = 59) then
                s_mins <= (others => '0');
            elsif s_secs = 59 then
                s_mins <= s_mins + 1;
            else
                s_mins <= s_mins;
            end if;
        end if;
    end process;

    -- Hours process
    process(CLK, RST)
    begin
        if RST = '1' then
            s_hours <= (others => '0');
        elsif rising_edge(CLK) then
            if (s_hours = 23) and (s_mins = 59) and (s_secs = 59) then
                s_hours <= (others => '0');
            elsif (s_mins = 59) and (s_secs = 59) then
                s_hours <= s_hours + 1;
            else
                s_hours <= s_hours;
            end if;
        end if;
    end process;

    Hours <= std_logic_vector(s_hours);
    Mins  <= std_logic_vector(s_mins);
    Secs  <= std_logic_vector(s_secs);

end Behavioral;
