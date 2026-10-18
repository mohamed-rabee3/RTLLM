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

architecture Behavioral of edge_detect is
    signal a_d : STD_LOGIC;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a_d  <= '0';
            rise <= '0';
            down <= '0';
        elsif rising_edge(clk) then
            a_d  <= a;
            rise <= a and (not a_d);
            down <= (not a) and a_d;
        end if;
    end process;

end Behavioral;
