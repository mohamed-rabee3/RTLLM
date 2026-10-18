library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pe is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        a   : in STD_LOGIC_VECTOR(31 downto 0);
        b   : in STD_LOGIC_VECTOR(31 downto 0);
        c   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end pe;

architecture RTL of pe is
    signal c_reg : unsigned(31 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            c_reg <= (others => '0');
        elsif rising_edge(clk) then
            c_reg <= c_reg + resize(unsigned(a) * unsigned(b), 32);
        end if;
    end process;

    c <= std_logic_vector(c_reg);
end RTL;
