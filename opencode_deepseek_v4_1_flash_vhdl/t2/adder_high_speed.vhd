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

architecture rtl of add_fast is
    signal a_low    : unsigned(7 downto 0);
    signal b_low    : unsigned(7 downto 0);
    signal a_high   : unsigned(7 downto 0);
    signal b_high   : unsigned(7 downto 0);
    signal sum_low  : unsigned(8 downto 0);
    signal sum_high0: unsigned(8 downto 0);
    signal sum_high1: unsigned(8 downto 0);
    signal sum_high : unsigned(8 downto 0);
    signal carry_low: std_logic;
begin
    a_low  <= unsigned(a(7 downto 0));
    b_low  <= unsigned(b(7 downto 0));
    a_high <= unsigned(a(15 downto 8));
    b_high <= unsigned(b(15 downto 8));

    sum_low <= ('0' & a_low) + ('0' & b_low);

    sum_high0 <= ('0' & a_high) + ('0' & b_high);
    sum_high1 <= ('0' & a_high) + ('0' & b_high) + 1;

    carry_low <= sum_low(8);
    sum_high  <= sum_high1 when carry_low = '1' else sum_high0;

    result(7 downto 0)   <= std_logic_vector(sum_low(7 downto 0));
    result(15 downto 8)  <= std_logic_vector(sum_high(7 downto 0));
    result(16)           <= sum_high(8);
end rtl;
