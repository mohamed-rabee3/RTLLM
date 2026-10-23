library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider is
    Port (
        dividend : in  signed(15 downto 0);
        divisor  : in  signed(15 downto 0);
        quotient : out signed(15 downto 0)
    );
end divider;

architecture rtl of divider is
begin
    process(dividend, divisor)
        variable num : signed(23 downto 0);
        variable den : signed(23 downto 0);
        variable res : signed(23 downto 0);
    begin
        if divisor = (others => '0') then
            quotient <= (others => '1');
        else
            num := shift_left(resize(dividend, 24), 7);
            den := resize(divisor, 24);
            res := num / den;
            quotient <= resize(res, 16);
        end if;
    end process;
end rtl;
