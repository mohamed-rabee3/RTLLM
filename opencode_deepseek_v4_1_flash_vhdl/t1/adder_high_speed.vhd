library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_fast is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add_fast;

architecture carry_select of add_fast is
    signal low_sum   : unsigned(8 downto 0);
    signal high_sum0 : unsigned(8 downto 0);
    signal high_sum1 : unsigned(8 downto 0);
    signal high_sum  : unsigned(8 downto 0);
begin

    low_sum <= resize(unsigned(a(7 downto 0)), 9) +
               resize(unsigned(b(7 downto 0)), 9);

    high_sum0 <= resize(unsigned(a(15 downto 8)), 9) +
                 resize(unsigned(b(15 downto 8)), 9);

    high_sum1 <= high_sum0 + to_unsigned(1, 9);

    high_sum <= high_sum1 when low_sum(8) = '1' else high_sum0;

    result <= std_logic_vector(high_sum(8 downto 0) & low_sum(7 downto 0));

end architecture carry_select;
