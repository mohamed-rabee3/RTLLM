library ieee;
use ieee.std_logic_1164.all;

entity ring_counter is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        \out\ : out std_logic_vector(7 downto 0)
    );
end entity ring_counter;

architecture rtl of ring_counter is
    signal state : std_logic_vector(7 downto 0);
begin
    process (clk, reset)
    begin
        if reset = '1' then
            state <= "00000001";
        elsif rising_edge(clk) then
            state <= state(6 downto 0) & state(7);
        end if;
    end process;

    \out\ <= state;
end architecture rtl;
