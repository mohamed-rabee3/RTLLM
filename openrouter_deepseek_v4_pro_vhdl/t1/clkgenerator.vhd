library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clkgenerator is
    generic (
        PERIOD : time := 10 ns
    );
    port (
        clk : out STD_LOGIC
    );
end entity clkgenerator;

architecture behavioral of clkgenerator is
    signal clk_int : STD_LOGIC := '0';
begin

    -- Process to generate the clock signal
    -- Toggles clk_int every half of the PERIOD
    clock_process: process
    begin
        clk_int <= not clk_int;
        wait for PERIOD / 2;
    end process clock_process;

    -- Assign internal clock signal to output port
    clk <= clk_int;

end architecture behavioral;