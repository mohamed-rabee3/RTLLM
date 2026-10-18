library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detect is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        a     : in  std_logic;
        rise  : out std_logic;
        down  : out std_logic
    );
end edge_detect;

architecture rtl of edge_detect is
    signal a_reg : std_logic;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a_reg <= '0';
            rise  <= '0';
            down  <= '0';
        elsif rising_edge(clk) then
            if (a = '1' and a_reg = '0') then
                rise <= '1';
            else
                rise <= '0';
            end if;

            if (a = '0' and a_reg = '1') then
                down <= '1';
            else
                down <= '0';
            end if;

            a_reg <= a;
        end if;
    end process;
end rtl;
