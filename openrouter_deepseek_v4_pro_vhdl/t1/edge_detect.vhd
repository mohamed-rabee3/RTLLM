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
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a_prev <= '0';
            rise   <= '0';
            down   <= '0';
        elsif rising_edge(clk) then
            -- Store current value for next comparison
            a_prev <= a;
            
            -- Detect rising edge: a = 1 and previous was 0
            if a = '1' and a_prev = '0' then
                rise <= '1';
            else
                rise <= '0';
            end if;
            
            -- Detect falling edge: a = 0 and previous was 1
            if a = '0' and a_prev = '1' then
                down <= '1';
            else
                down <= '0';
            end if;
        end if;
    end process;
end architecture rtl;