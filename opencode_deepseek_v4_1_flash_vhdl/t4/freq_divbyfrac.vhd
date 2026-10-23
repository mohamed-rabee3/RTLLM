library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_divbyfrac is
    Port ( clk     : in  STD_LOGIC;
           rst_n   : in  STD_LOGIC;
           clk_div : out STD_LOGIC);
end freq_divbyfrac;

architecture Behavioral of freq_divbyfrac is
    constant MUL2_DIV_CLK : integer := 7;
    signal cnt       : integer range 0 to MUL2_DIV_CLK-1 := 0;
    signal clk_div_r1 : std_logic := '0';
    signal clk_div_r2 : std_logic := '0';
begin

    -- Counter process
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= 0;
        elsif rising_edge(clk) then
            if cnt = MUL2_DIV_CLK-1 then
                cnt <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    -- First intermediate clock (rising edge)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_r1 <= '0';
        elsif rising_edge(clk) then
            if cnt = 0 then
                clk_div_r1 <= '1';
            elsif cnt = MUL2_DIV_CLK/2 then
                clk_div_r1 <= '0';
            end if;
        end if;
    end process;

    -- Second intermediate clock (falling edge, phase-shifted by half clock)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_r2 <= '0';
        elsif falling_edge(clk) then
            clk_div_r2 <= clk_div_r1;
        end if;
    end process;

    -- Final fractional divided clock output
    clk_div <= clk_div_r1 or clk_div_r2;

end Behavioral;
