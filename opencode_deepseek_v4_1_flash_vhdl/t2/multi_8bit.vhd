library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_8bit is
    port (
        A       : in  std_logic_vector(7 downto 0);
        B       : in  std_logic_vector(7 downto 0);
        product : out std_logic_vector(15 downto 0)
    );
end multi_8bit;

architecture rtl of multi_8bit is
begin
    process(A, B)
        variable multiplicand : unsigned(15 downto 0);
        variable multiplier   : unsigned(7 downto 0);
        variable result       : unsigned(15 downto 0);
    begin
        multiplicand := resize(unsigned(A), 16);
        multiplier   := unsigned(B);
        result       := (others => '0');

        for i in 0 to 7 loop
            if multiplier(0) = '1' then
                result := result + multiplicand;
            end if;

            multiplicand := multiplicand(14 downto 0) & '0';
            multiplier   := '0' & multiplier(7 downto 1);
        end loop;

        product <= std_logic_vector(result);
    end process;
end rtl;
