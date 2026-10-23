library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider is
    Port (
        dividend : in  std_logic_vector(15 downto 0);
        divisor  : in  std_logic_vector(15 downto 0);
        quotient : out std_logic_vector(15 downto 0)
    );
end divider;

architecture rtl of divider is
begin
    process(dividend, divisor)
        variable num : signed(23 downto 0);
        variable den : signed(15 downto 0);
        variable quo : signed(15 downto 0);
    begin
        den := signed(divisor);
        num := shift_left(resize(signed(dividend), 24), 7);

        if den = 0 then
            quotient <= x"FFFF";
        else
            quo := resize(num / den, 16);
            quotient <= std_logic_vector(quo);
        end if;
    end process;
end rtl;
