library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_fast is
    Port ( a : in STD_LOGIC_VECTOR (15 downto 0);
           b : in STD_LOGIC_VECTOR (15 downto 0);
           result : out STD_LOGIC_VECTOR (16 downto 0));
end add_fast;

architecture rtl of add_fast is
    signal a_low      : unsigned(8 downto 0);
    signal b_low      : unsigned(8 downto 0);
    signal a_high     : unsigned(8 downto 0);
    signal b_high     : unsigned(8 downto 0);
    signal lower_sum9 : unsigned(8 downto 0);
    signal upper_sum0 : unsigned(8 downto 0);
    signal upper_sum1 : unsigned(8 downto 0);
    signal upper_sel  : unsigned(8 downto 0);
begin
    a_low  <= resize(unsigned(a(7 downto 0)), 9);
    b_low  <= resize(unsigned(b(7 downto 0)), 9);
    lower_sum9 <= a_low + b_low;

    a_high <= resize(unsigned(a(15 downto 8)), 9);
    b_high <= resize(unsigned(b(15 downto 8)), 9);
    upper_sum0 <= a_high + b_high;
    upper_sum1 <= upper_sum0 + 1;

    upper_sel <= upper_sum0 when lower_sum9(8) = '0' else upper_sum1;

    result(16)          <= upper_sel(8);
    result(15 downto 8) <= std_logic_vector(upper_sel(7 downto 0));
    result(7 downto 0)  <= std_logic_vector(lower_sum9(7 downto 0));
end rtl;
