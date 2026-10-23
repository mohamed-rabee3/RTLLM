library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_diveven is
    generic (
        NUM_DIV : positive := 10
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end entity freq_diveven;

architecture rtl of freq_diveven is
    constant HALF_PERIOD : positive := NUM_DIV / 2;
    signal cnt         : unsigned(3 downto 0);
    signal clk_div_reg : std_logic;
begin
    clk_div <= clk_div_reg;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cnt         <= (others => '0');
            clk_div_reg <= '0';
        elsif rising_edge(clk) then
            if to_integer(cnt) < HALF_PERIOD - 1 then
                cnt <= cnt + 1;
            else
                cnt         <= (others => '0');
                clk_div_reg <= not clk_div_reg;
            end if;
        end if;
    end process;
end architecture rtl;
