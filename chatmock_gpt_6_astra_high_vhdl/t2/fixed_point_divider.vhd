library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    port (
        dividend : in  std_logic_vector(15 downto 0);
        divisor  : in  std_logic_vector(15 downto 0);
        quotient : out std_logic_vector(15 downto 0)
    );
end entity divider;

architecture rtl of divider is
begin
    process(dividend, divisor)
        variable scaled_dividend : signed(23 downto 0);
        variable extended_divisor : signed(23 downto 0);
        variable division_result : signed(23 downto 0);
    begin
        if divisor = x"0000" then
            quotient <= x"FFFF";
        else
            scaled_dividend := shift_left(resize(signed(dividend), 24), 7);
            extended_divisor := resize(signed(divisor), 24);
            division_result := scaled_dividend / extended_divisor;
            quotient <= std_logic_vector(division_result(15 downto 0));
        end if;
    end process;
end architecture rtl;
