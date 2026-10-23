library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_diveven is
    generic (
        NUM_DIV : integer := 10
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end freq_diveven;

architecture rtl of freq_diveven is
    signal cnt         : integer range 0 to 15 := 0;
    signal clk_div_reg : std_logic := '0';
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt         <= 0;
            clk_div_reg <= '0';
        elsif rising_edge(clk) then
            if cnt < NUM_DIV / 2 - 1 then
                cnt <= cnt + 1;
            else
                cnt         <= 0;
                clk_div_reg <= not clk_div_reg;
            end if;
        end if;
    end process;

    clk_div <= clk_div_reg;
end rtl;
