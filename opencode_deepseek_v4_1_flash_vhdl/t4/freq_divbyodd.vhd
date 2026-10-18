library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_divbyodd is
    generic (
        NUM_DIV : integer := 5
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end freq_divbyodd;

architecture rtl of freq_divbyodd is
    constant HALF_DIV : integer := (NUM_DIV - 1) / 2;
    signal cnt1     : integer range 0 to NUM_DIV - 1 := 0;
    signal cnt2     : integer range 0 to NUM_DIV - 1 := 0;
    signal clk_div1 : std_logic := '0';
    signal clk_div2 : std_logic := '0';
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt1     <= 0;
            clk_div1 <= '0';
        elsif rising_edge(clk) then
            if cnt1 = NUM_DIV - 1 then
                cnt1 <= 0;
            else
                cnt1 <= cnt1 + 1;
            end if;

            if (cnt1 = HALF_DIV) or (cnt1 = NUM_DIV - 1) then
                clk_div1 <= not clk_div1;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt2     <= 0;
            clk_div2 <= '0';
        elsif falling_edge(clk) then
            if cnt2 = NUM_DIV - 1 then
                cnt2 <= 0;
            else
                cnt2 <= cnt2 + 1;
            end if;

            if (cnt2 = HALF_DIV) or (cnt2 = NUM_DIV - 1) then
                clk_div2 <= not clk_div2;
            end if;
        end if;
    end process;

    clk_div <= clk_div1 or clk_div2;

end rtl;
