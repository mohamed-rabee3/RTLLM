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
    signal secs_reg  : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
    signal mins_reg  : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');
    signal hours_reg : STD_LOGIC_VECTOR (5 downto 0) := (others => '0');

    constant MAX_SEC_MIN : STD_LOGIC_VECTOR (5 downto 0) := "111011"; -- 59
    constant MAX_HOUR    : STD_LOGIC_VECTOR (5 downto 0) := "010111"; -- 23
begin

    -- Seconds counter process
    process (CLK, RST)
    begin
        if RST = '1' then
            secs_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if secs_reg = MAX_SEC_MIN then
                secs_reg <= (others => '0');
            else
                secs_reg <= std_logic_vector(unsigned(secs_reg) + 1);
            end if;
        end if;
    end process;

    -- Minutes counter process
    process (CLK, RST)
    begin
        if RST = '1' then
            mins_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if mins_reg = MAX_SEC_MIN and secs_reg = MAX_SEC_MIN then
                mins_reg <= (others => '0');
            elsif secs_reg = MAX_SEC_MIN then
                mins_reg <= std_logic_vector(unsigned(mins_reg) + 1);
            else
                mins_reg <= mins_reg;
            end if;
        end if;
    end process;

    -- Hours counter process
    process (CLK, RST)
    begin
        if RST = '1' then
            hours_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if hours_reg = MAX_HOUR and mins_reg = MAX_SEC_MIN and secs_reg = MAX_SEC_MIN then
                hours_reg <= (others => '0');
            elsif mins_reg = MAX_SEC_MIN and secs_reg = MAX_SEC_MIN then
                hours_reg <= std_logic_vector(unsigned(hours_reg) + 1);
            else
                hours_reg <= hours_reg;
            end if;
        end if;
    end process;

    Hours <= hours_reg;
    Mins  <= mins_reg;
    Secs  <= secs_reg;

end Behavioral;
