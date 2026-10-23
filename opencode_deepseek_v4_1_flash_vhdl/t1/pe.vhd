library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pe is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic_vector(31 downto 0);
        b   : in  std_logic_vector(31 downto 0);
        c   : out std_logic_vector(31 downto 0)
    );
end entity pe;

architecture rtl of pe is
    signal acc : unsigned(31 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            acc <= (others => '0');
        elsif rising_edge(clk) then
            acc <= acc + resize(unsigned(a) * unsigned(b), 32);
        end if;
    end process;

    c <= std_logic_vector(acc);
end architecture rtl;
