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

architecture Behavioral of clkgenerator is
    signal clk_int : std_logic := '0';
begin
    clk <= clk_int;

    process
    begin
        wait for (PERIOD / 2) * 1 ns;
        clk_int <= not clk_int;
    end process;
end Behavioral;
