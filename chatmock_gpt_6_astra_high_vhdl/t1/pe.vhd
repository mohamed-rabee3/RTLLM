library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    signal accumulator : unsigned(31 downto 0);
begin
    process (clk, rst)
        variable product : unsigned(63 downto 0);
    begin
        if rst = '1' then
            accumulator <= (others => '0');
        elsif rising_edge(clk) then
            product := unsigned(a) * unsigned(b);
            accumulator <= accumulator + product(31 downto 0);
        end if;
    end process;

    c <= std_logic_vector(accumulator);
end architecture rtl;
