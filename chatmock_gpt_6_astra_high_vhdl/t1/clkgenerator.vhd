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
    signal clk_internal : std_logic := '0';
begin
    clk <= clk_internal;

    -- Autonomous time-based clock generation is simulation-only;
    -- hardware implementation requires a physical clock source.
    clock_process : process
    begin
        wait for HALF_PERIOD;
        clk_internal <= not clk_internal;
    end process clock_process;
end architecture behavioral;
