library ieee;
use ieee.std_logic_1164.all;

entity clkgenerator is
    generic (
        PERIOD : positive := 10
    );
    port (
        clk : out std_logic
    );
end entity clkgenerator;

architecture behavioral of clkgenerator is
    constant HALF_PERIOD : time := (PERIOD * 1 ns) / 2;
begin
    clock_process : process
    begin
        clk <= '0';
        wait for HALF_PERIOD;
        clk <= '1';
        wait for HALF_PERIOD;
    end process clock_process;
end architecture behavioral;
