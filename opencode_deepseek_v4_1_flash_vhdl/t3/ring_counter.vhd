library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ring_counter is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        \out\ : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ring_counter;

architecture Behavioral of ring_counter is
    signal state : STD_LOGIC_VECTOR(7 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= "00000001";
        elsif rising_edge(clk) then
            state <= state(6 downto 0) & state(7);
        end if;
    end process;

    \out\ <= state;
end Behavioral;
