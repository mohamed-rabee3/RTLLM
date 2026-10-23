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
        variable product      : unsigned(31 downto 0);
        variable multiplicand : unsigned(31 downto 0);
    begin
        product      := (others => '0');
        multiplicand := resize(unsigned(a), 32);

        for i in 0 to 15 loop
            if b(i) = '1' then
                product := product + shift_left(multiplicand, i);
            end if;
        end loop;

        result <= std_logic_vector(product);
    end process;
end architecture rtl;
