library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity calendar is
    port (
        CLK   : in  std_logic;
        RST   : in  std_logic;
        Hours : out std_logic_vector(5 downto 0);
        Mins  : out std_logic_vector(5 downto 0);
        Secs  : out std_logic_vector(5 downto 0)
    );
end entity calendar;

architecture Behavioral of calendar is

    -- Internal registers for seconds, minutes, and hours
    signal secs_reg  : unsigned(5 downto 0) := (others => '0');
    signal mins_reg  : unsigned(5 downto 0) := (others => '0');
    signal hours_reg : unsigned(5 downto 0) := (others => '0');

begin

    -- Process for Seconds
    secs_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            secs_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if secs_reg = 59 then
                secs_reg <= (others => '0');
            else
                secs_reg <= secs_reg + 1;
            end if;
        end if;
    end process secs_proc;

    -- Process for Minutes
    mins_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            mins_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if (mins_reg = 59) and (secs_reg = 59) then
                mins_reg <= (others => '0');
            elsif secs_reg = 59 then
                mins_reg <= mins_reg + 1;
            else
                mins_reg <= mins_reg;
            end if;
        end if;
    end process mins_proc;

    -- Process for Hours
    hours_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            hours_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if (hours_reg = 23) and (mins_reg = 59) and (secs_reg = 59) then
                hours_reg <= (others => '0');
            elsif (mins_reg = 59) and (secs_reg = 59) then
                hours_reg <= hours_reg + 1;
            else
                hours_reg <= hours_reg;
            end if;
        end if;
    end process hours_proc;

    -- Connect internal registers to output ports
    Secs  <= std_logic_vector(secs_reg);
    Mins  <= std_logic_vector(mins_reg);
    Hours <= std_logic_vector(hours_reg);

end architecture Behavioral;