library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_8bit is
    port (
        A       : in  STD_LOGIC_VECTOR(7 downto 0);
        B       : in  STD_LOGIC_VECTOR(7 downto 0);
        product : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity multi_8bit;

architecture rtl of multi_8bit is
begin
    process(A, B)
        variable accumulator  : UNSIGNED(15 downto 0);
        variable multiplicand : UNSIGNED(15 downto 0);
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
