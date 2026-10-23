library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ring_counter is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        \out\ : out STD_LOGIC_VECTOR(7 downto 0)
    );
end ring_counter;

architecture rtl of ring_counter is
    signal q : STD_LOGIC_VECTOR(7 downto 0) := "00000001";
begin
    process(clk, reset)
    begin
        if reset = '1' then
            q <= "00000001";
        elsif rising_edge(clk) then
            q <= q(6 downto 0) & q(7);
        end if;
    end process;

    \out\ <= q;
end rtl;
