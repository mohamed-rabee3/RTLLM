library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_low_power is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul_low_power;

architecture rtl of mul_low_power is
begin
    process(a, b)
        variable product         : unsigned(31 downto 0);
        variable partial_product : unsigned(31 downto 0);
    begin
        product := (others => '0');

        for i in 0 to 15 loop
            partial_product := (others => '0');
            for j in 0 to 15 loop
                partial_product(i + j) := a(j) and b(i);
            end loop;
            product := product + partial_product;
        end loop;

        result <= std_logic_vector(product);
    end process;
end architecture rtl;
