library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    port (
        dividend : in  signed(15 downto 0);
        divisor  : in  signed(15 downto 0);
        quotient : out signed(15 downto 0)
    );
end entity divider;

architecture rtl of divider is
begin
    process (dividend, divisor)
        variable scaled_dividend : signed(23 downto 0);
        variable division_result : signed(23 downto 0);
    begin
        if divisor = to_signed(0, divisor'length) then
            quotient <= (others => '1');
        else
            scaled_dividend := shift_left(resize(dividend, 24), 7);
            division_result := scaled_dividend / resize(divisor, 24);
            quotient <= division_result(15 downto 0);
        end if;
    end process;
end architecture rtl;
