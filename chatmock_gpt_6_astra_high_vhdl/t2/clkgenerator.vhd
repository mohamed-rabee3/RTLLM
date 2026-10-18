library ieee;
use ieee.std_logic_1164.all;

entity clkgenerator is
    generic (
        PERIOD : integer := 10
    );
    port (
        clk : out std_logic
    );
end entity clkgenerator;

architecture behavioral of clkgenerator is
begin
    -- An autonomous, delay-based clock generator is simulation-only;
    -- synthesizable clock generation requires a reference clock or oscillator.
    clock_process : process
    begin
        clk <= '0';
        loop
            wait for (PERIOD / 2) * 1 ns;
            clk <= '1';
            wait for (PERIOD / 2) * 1 ns;
            clk <= '0';
        end loop;
    end process clock_process;
end architecture behavioral;
