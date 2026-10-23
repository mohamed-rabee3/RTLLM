library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity freq_diveven is
    generic (
        NUM_DIV : integer := 8
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end entity freq_diveven;

architecture rtl of freq_diveven is
    signal cnt       : unsigned(3 downto 0);
    signal clk_div_i : std_logic;
begin
    clk_div <= clk_div_i;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt       <= (others => '0');
            clk_div_i <= '0';
        elsif rising_edge(clk) then
            if cnt < to_unsigned((NUM_DIV / 2) - 1, cnt'length) then
                cnt <= cnt + 1;
            else
                cnt       <= (others => '0');
                clk_div_i <= not clk_div_i;
            end if;
        end if;
    end process;
end architecture rtl;
