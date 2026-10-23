library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        a     : in  std_logic;
        rise  : out std_logic;
        down  : out std_logic
    );
end entity edge_detect;

architecture rtl of edge_detect is
    signal a_prev : std_logic;
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            a_prev <= '0';
            rise   <= '0';
            down   <= '0';
        elsif rising_edge(clk) then
            rise   <= a and not a_prev;
            down   <= not a and a_prev;
            a_prev <= a;
        end if;
    end process;
end architecture rtl;
