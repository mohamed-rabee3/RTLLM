library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_fast is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (16 downto 0)
    );
end add_fast;

architecture carry_select of add_fast is
    signal low_sum   : unsigned(8 downto 0);
    signal high_sum0 : unsigned(8 downto 0);
    signal high_sum1 : unsigned(8 downto 0);
    signal high_sum  : unsigned(8 downto 0);
begin
    low_sum <= ('0' & unsigned(a(7 downto 0))) + ('0' & unsigned(b(7 downto 0)));

    high_sum0 <= ('0' & unsigned(a(15 downto 8))) + ('0' & unsigned(b(15 downto 8)));
    high_sum1 <= ('0' & unsigned(a(15 downto 8))) + ('0' & unsigned(b(15 downto 8))) + 1;

    high_sum <= high_sum1 when low_sum(8) = '1' else high_sum0;

    result <= std_logic_vector(high_sum) & std_logic_vector(low_sum(7 downto 0));
end carry_select;
