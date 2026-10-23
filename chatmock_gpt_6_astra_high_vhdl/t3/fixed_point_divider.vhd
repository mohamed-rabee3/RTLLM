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
        variable full_quotient   : signed(23 downto 0);
    begin
        scaled_dividend := shift_left(resize(dividend, 24), 7);
        full_quotient := (others => '0');

        if divisor = to_signed(0, 16) then
            quotient <= (others => '1');
        else
            full_quotient := scaled_dividend / resize(divisor, 24);
            quotient <= full_quotient(15 downto 0);
        end if;
    end process;
end architecture rtl;
