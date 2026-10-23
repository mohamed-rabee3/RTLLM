library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sub_64bit is
    Port (
        A        : in  STD_LOGIC_VECTOR(63 downto 0);
        B        : in  STD_LOGIC_VECTOR(63 downto 0);
        result   : out STD_LOGIC_VECTOR(63 downto 0);
        overflow : out STD_LOGIC
    );
end sub_64bit;

architecture rtl of sub_64bit is
    signal a_s : signed(63 downto 0);
    signal b_s : signed(63 downto 0);
    signal r_s : signed(63 downto 0);
begin
    a_s <= signed(A);
    b_s <= signed(B);
    r_s <= a_s - b_s;

    result <= std_logic_vector(r_s);

    overflow <= '1' when
        (A(63) = '0' and B(63) = '1' and r_s(63) = '1') or
        (A(63) = '1' and B(63) = '0' and r_s(63) = '0')
        else '0';
end rtl;
