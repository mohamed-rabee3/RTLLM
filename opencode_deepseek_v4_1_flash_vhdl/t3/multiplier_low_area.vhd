library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_low_area is
    Port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end mul_low_area;

architecture rtl of mul_low_area is
begin
    process(a, b)
        variable acc : unsigned(31 downto 0);
    begin
        acc := (others => '0');

        for i in natural range 0 to 15 loop
            if b(i) = '1' then
                acc := acc + shift_left(resize(unsigned(a), 32), i);
            end if;
        end loop;

        result <= std_logic_vector(acc);
    end process;
end rtl;
