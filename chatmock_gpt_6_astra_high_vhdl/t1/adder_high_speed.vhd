library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_fast is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add_fast;

architecture rtl of add_fast is
    signal low_sum   : unsigned(8 downto 0);
    signal high_sum0 : unsigned(8 downto 0);
    signal high_sum1 : unsigned(8 downto 0);
    signal high_sum  : unsigned(8 downto 0);
begin
    low_sum <= resize(unsigned(a(7 downto 0)), 9)
             + resize(unsigned(b(7 downto 0)), 9);

    high_sum0 <= resize(unsigned(a(15 downto 8)), 9)
               + resize(unsigned(b(15 downto 8)), 9);

    high_sum1 <= resize(unsigned(a(15 downto 8)), 9)
               + resize(unsigned(b(15 downto 8)), 9)
               + to_unsigned(1, 9);

    high_sum <= high_sum1 when low_sum(8) = '1' else high_sum0;

    result <= std_logic_vector(high_sum) &
              std_logic_vector(low_sum(7 downto 0));
end architecture rtl;
