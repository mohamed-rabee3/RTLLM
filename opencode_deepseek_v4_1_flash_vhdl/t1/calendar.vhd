library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity calendar is
    Port (
        CLK   : in  STD_LOGIC;
        RST   : in  STD_LOGIC;
        Hours : out STD_LOGIC_VECTOR (5 downto 0);
        Mins  : out STD_LOGIC_VECTOR (5 downto 0);
        Secs  : out STD_LOGIC_VECTOR (5 downto 0)
    );
end calendar;

architecture Behavioral of calendar is
    signal sec_reg : unsigned(5 downto 0) := (others => '0');
    signal min_reg : unsigned(5 downto 0) := (others => '0');
    signal hr_reg  : unsigned(5 downto 0) := (others => '0');
begin

    Secs  <= std_logic_vector(sec_reg);
    Mins  <= std_logic_vector(min_reg);
    Hours <= std_logic_vector(hr_reg);

    process(CLK, RST)
    begin
        if RST = '1' then
            sec_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if sec_reg = 59 then
                sec_reg <= (others => '0');
            else
                sec_reg <= sec_reg + 1;
            end if;
        end if;
    end process;

    process(CLK, RST)
    begin
        if RST = '1' then
            min_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if (min_reg = 59) and (sec_reg = 59) then
                min_reg <= (others => '0');
            elsif sec_reg = 59 then
                min_reg <= min_reg + 1;
            else
                min_reg <= min_reg;
            end if;
        end if;
    end process;

    process(CLK, RST)
    begin
        if RST = '1' then
            hr_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if (hr_reg = 23) and (min_reg = 59) and (sec_reg = 59) then
                hr_reg <= (others => '0');
            elsif (min_reg = 59) and (sec_reg = 59) then
                hr_reg <= hr_reg + 1;
            else
                hr_reg <= hr_reg;
            end if;
        end if;
    end process;

end Behavioral;
