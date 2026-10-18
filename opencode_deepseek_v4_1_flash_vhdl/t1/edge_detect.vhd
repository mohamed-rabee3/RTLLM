library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detect is
    Port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        a     : in  STD_LOGIC;
        rise  : out STD_LOGIC;
        down  : out STD_LOGIC
    );
end edge_detect;

architecture rtl of edge_detect is
    signal a_prev : STD_LOGIC;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a_prev <= '0';
            rise   <= '0';
            down   <= '0';
        elsif rising_edge(clk) then
            a_prev <= a;

            if (a = '1' and a_prev = '0') then
                rise <= '1';
            else
                rise <= '0';
            end if;

            if (a = '0' and a_prev = '1') then
                down <= '1';
            else
                down <= '0';
            end if;
        end if;
    end process;

end rtl;
