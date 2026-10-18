library ieee;
use ieee.std_logic_1164.all;

entity freq_divbyodd is
    generic (
        NUM_DIV : positive := 5
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end entity freq_divbyodd;

architecture rtl of freq_divbyodd is
    signal cnt1     : natural range 0 to NUM_DIV - 1;
    signal cnt2     : natural range 0 to NUM_DIV - 1;
    signal clk_div1 : std_logic;
    signal clk_div2 : std_logic;
begin

    gen_divide_by_one : if NUM_DIV = 1 generate
        clk_div <= clk and rst_n;
    end generate gen_divide_by_one;

    gen_odd_divider : if NUM_DIV > 1 generate
        process (clk, rst_n)
        begin
            if rst_n = '0' then
                cnt1     <= 0;
                clk_div1 <= '0';
            elsif rising_edge(clk) then
                if cnt1 = NUM_DIV - 1 then
                    cnt1     <= 0;
                    clk_div1 <= not clk_div1;
                else
                    cnt1 <= cnt1 + 1;
                    if cnt1 = (NUM_DIV - 1) / 2 then
                        clk_div1 <= not clk_div1;
                    end if;
                end if;
            end if;
        end process;

        process (clk, rst_n)
        begin
            if rst_n = '0' then
                cnt2     <= 0;
                clk_div2 <= '0';
            elsif falling_edge(clk) then
                if cnt2 = NUM_DIV - 1 then
                    cnt2     <= 0;
                    clk_div2 <= not clk_div2;
                else
                    cnt2 <= cnt2 + 1;
                    if cnt2 = (NUM_DIV - 1) / 2 then
                        clk_div2 <= not clk_div2;
                    end if;
                end if;
            end if;
        end process;

        clk_div <= clk_div1 or clk_div2;
    end generate gen_odd_divider;

end architecture rtl;
