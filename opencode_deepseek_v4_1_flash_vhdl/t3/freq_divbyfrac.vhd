library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_divbyfrac is
    Port ( clk     : in  STD_LOGIC;
           rst_n   : in  STD_LOGIC;
           clk_div : out STD_LOGIC);
end freq_divbyfrac;

architecture Behavioral of freq_divbyfrac is
    signal cnt      : integer range 0 to 6 := 0;
    signal clk_div1 : std_logic := '0';
    signal clk_div2 : std_logic := '0';
begin

    -- Modulo-7 counter
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= 0;
        elsif rising_edge(clk) then
            if cnt = 6 then
                cnt <= 0;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    -- First intermediate clock (rising-edge based)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div1 <= '0';
        elsif rising_edge(clk) then
            if cnt = 0 then
                clk_div1 <= '1';
            elsif cnt = 3 then
                clk_div1 <= '0';
            end if;
        end if;
    end process;

    -- Second intermediate clock (falling-edge based, phase shifted by half period)
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div2 <= '0';
        elsif falling_edge(clk) then
            if cnt = 4 then
                clk_div2 <= '1';
            elsif cnt = 0 then
                clk_div2 <= '0';
            end if;
        end if;
    end process;

    -- OR the two intermediate clocks to create the fractional divided output
    clk_div <= clk_div1 or clk_div2;

end Behavioral;
