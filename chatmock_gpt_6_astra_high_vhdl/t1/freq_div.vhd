library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_div is
    port (
        CLK_in : in  std_logic;
        RST    : in  std_logic;
        CLK_50 : out std_logic;
        CLK_10 : out std_logic;
        CLK_1  : out std_logic
    );
end entity freq_div;

architecture RTL of freq_div is
    signal clk_50_reg : std_logic;
    signal clk_10_reg : std_logic;
    signal clk_1_reg  : std_logic;
    signal cnt_10    : integer range 0 to 4;
    signal cnt_100   : integer range 0 to 49;
begin
    CLK_50 <= clk_50_reg;
    CLK_10 <= clk_10_reg;
    CLK_1  <= clk_1_reg;

    process (CLK_in, RST)
    begin
        if RST = '1' then
            clk_50_reg <= '0';
        elsif rising_edge(CLK_in) then
            clk_50_reg <= not clk_50_reg;
        end if;
    end process;

    process (CLK_in, RST)
    begin
        if RST = '1' then
            clk_10_reg <= '0';
            cnt_10 <= 0;
        elsif rising_edge(CLK_in) then
            if cnt_10 = 4 then
                clk_10_reg <= not clk_10_reg;
                cnt_10 <= 0;
            else
                cnt_10 <= cnt_10 + 1;
            end if;
        end if;
    end process;

    process (CLK_in, RST)
    begin
        if RST = '1' then
            clk_1_reg <= '0';
            cnt_100 <= 0;
        elsif rising_edge(CLK_in) then
            if cnt_100 = 49 then
                clk_1_reg <= not clk_1_reg;
                cnt_100 <= 0;
            else
                cnt_100 <= cnt_100 + 1;
            end if;
        end if;
    end process;
end architecture RTL;
