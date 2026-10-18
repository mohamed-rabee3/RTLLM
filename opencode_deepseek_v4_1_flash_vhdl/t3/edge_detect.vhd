library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detect is
    Port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        a     : in  std_logic;
        rise  : out std_logic;
        down  : out std_logic
    );
end edge_detect;

architecture rtl of edge_detect is
    signal a_d : std_logic;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a_d  <= '0';
            rise <= '0';
            down <= '0';
        elsif rising_edge(clk) then
            a_d <= a;

            rise <= '0';
            down <= '0';

            if (a = '1' and a_d = '0') then
                rise <= '1';
            elsif (a = '0' and a_d = '1') then
                down <= '1';
            end if;
        end if;
    end process;

end rtl;
