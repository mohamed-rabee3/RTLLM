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
    constant HALF_PERIOD : time := (PERIOD / 2) * 1 ns;
    signal clk_int : std_logic := '0';
begin
    clk <= clk_int;

    process
    begin
        loop
            wait for HALF_PERIOD;
            clk_int <= not clk_int;
        end loop;
    end process;
end Behavioral;
