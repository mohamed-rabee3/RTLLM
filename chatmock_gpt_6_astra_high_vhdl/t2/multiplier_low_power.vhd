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
        variable accumulator   : unsigned(31 downto 0);
        variable partial_product : unsigned(31 downto 0);
    begin
        accumulator := (others => '0');

        for i in 0 to 15 loop
            partial_product := (others => '0');
            if b(i) = '1' then
                partial_product := shift_left(resize(unsigned(a), 32), i);
            end if;
            accumulator := accumulator + partial_product;
        end loop;

        result <= std_logic_vector(accumulator);
    end process;
end architecture rtl;
