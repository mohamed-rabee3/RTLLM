library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clkgenerator is
    generic (
        PERIOD : integer := 10
    );
    port (
        clk : out std_logic
    );
end clkgenerator;

architecture rtl of clkgenerator is
begin
    process
    begin
        clk <= '0';
        wait for (PERIOD / 2) * 1 ns;
        clk <= '1';
        wait for (PERIOD / 2) * 1 ns;
    end process;
end rtl;
