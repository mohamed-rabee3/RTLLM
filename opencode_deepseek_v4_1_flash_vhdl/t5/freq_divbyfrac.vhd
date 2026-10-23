library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_divbyfrac is
    Port (
        clk     : in  STD_LOGIC;
        rst_n   : in  STD_LOGIC;
        clk_div : out STD_LOGIC
    );
end freq_divbyfrac;

architecture rtl of freq_divbyfrac is
    constant MUL2_DIV_CLK : integer := 7;
    signal cnt : integer range 0 to MUL2_DIV_CLK-1 := 0;
    signal clk_div_temp1 : STD_LOGIC := '0';
    signal clk_div_temp2 : STD_LOGIC := '0';
begin

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

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_temp1 <= '0';
        elsif rising_edge(clk) then
            if cnt = 0 then
                clk_div_temp1 <= '1';
            elsif cnt = 1 then
                clk_div_temp1 <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_temp2 <= '0';
        elsif falling_edge(clk) then
            if cnt = 1 then
                clk_div_temp2 <= '1';
            elsif cnt = 2 then
                clk_div_temp2 <= '0';
            elsif cnt = 4 then
                clk_div_temp2 <= '1';
            elsif cnt = 6 then
                clk_div_temp2 <= '0';
            end if;
        end if;
    end process;

    clk_div <= clk_div_temp1 or clk_div_temp2;

end rtl;
