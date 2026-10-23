library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity JC_counter is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        Q     : out std_logic_vector(63 downto 0)
    );
end entity JC_counter;

architecture RTL of JC_counter is
    signal count_reg : std_logic_vector(63 downto 0);
begin
    Q <= count_reg;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            count_reg <= (not count_reg(0)) & count_reg(63 downto 1);
        end if;
    end process;
end architecture RTL;
