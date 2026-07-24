library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_mul_low_area is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(31 downto 0));
end verified_mul_low_area;
architecture rtl of verified_mul_low_area is
begin
    process(a, b)
        variable acc : unsigned(31 downto 0);
    begin
        acc := (others => '0');
        for i in 0 to 15 loop
            if b(i) = '1' then
                acc := acc + shift_left(resize(unsigned(a), 32), i);
            end if;
        end loop;
        result <= std_logic_vector(acc);
    end process;
end rtl;
