library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_low_area is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul_low_area;

architecture rtl of mul_low_area is
begin
    process(a, b)
        variable sum_v : unsigned(31 downto 0);
        variable a_v   : unsigned(31 downto 0);
    begin
        sum_v := (others => '0');
        a_v   := resize(unsigned(a), 32);

        for i in 0 to 15 loop
            if b(i) = '1' then
                sum_v := sum_v + shift_left(a_v, i);
            end if;
        end loop;

        result <= std_logic_vector(sum_v);
    end process;
end architecture rtl;
