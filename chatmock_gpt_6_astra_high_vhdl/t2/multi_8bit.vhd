library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_8bit is
    port (
        A       : in  std_logic_vector(7 downto 0);
        B       : in  std_logic_vector(7 downto 0);
        product : out std_logic_vector(15 downto 0)
    );
end entity multi_8bit;

architecture rtl of multi_8bit is
begin
    process (A, B)
        variable accumulator  : unsigned(15 downto 0);
        variable multiplicand : unsigned(15 downto 0);
    begin
        accumulator  := (others => '0');
        multiplicand := resize(unsigned(A), 16);

        for i in 0 to 7 loop
            if B(i) = '1' then
                accumulator := accumulator + multiplicand;
            end if;
            multiplicand := shift_left(multiplicand, 1);
        end loop;

        product <= std_logic_vector(accumulator);
    end process;
end architecture rtl;
