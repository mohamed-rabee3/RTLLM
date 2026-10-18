library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity JC_counter is
    port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        Q     : out STD_LOGIC_VECTOR(63 downto 0)
    );
end entity JC_counter;

architecture RTL of JC_counter is
    signal count_reg : STD_LOGIC_VECTOR(63 downto 0);
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            count_reg <= (not count_reg(0)) & count_reg(63 downto 1);
        end if;
    end process;

    Q <= count_reg;
end architecture RTL;
