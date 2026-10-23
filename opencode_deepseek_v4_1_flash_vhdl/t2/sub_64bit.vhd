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

architecture RTL of sub_64bit is
    signal A_s      : signed(63 downto 0);
    signal B_s      : signed(63 downto 0);
    signal result_s : signed(63 downto 0);
begin
    A_s      <= signed(A);
    B_s      <= signed(B);
    result_s <= A_s - B_s;

    result <= std_logic_vector(result_s);

    overflow <= '1' when (A_s(63) /= B_s(63)) and (result_s(63) /= A_s(63)) else '0';
end RTL;
