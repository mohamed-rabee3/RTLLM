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
        variable accumulator : unsigned(31 downto 0);
        variable extended_a  : unsigned(31 downto 0);
    begin
        accumulator := (others => '0');
        extended_a  := resize(unsigned(a), 32);

        for i in 0 to 15 loop
            if b(i) = '1' then
                accumulator := accumulator + shift_left(extended_a, i);
            end if;
        end loop;

        result <= std_logic_vector(accumulator);
    end process;
end architecture rtl;
