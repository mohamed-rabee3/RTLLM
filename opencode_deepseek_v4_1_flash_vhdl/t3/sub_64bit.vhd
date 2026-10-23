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

architecture Behavioral of sub_64bit is
    signal result_s : signed(63 downto 0);
begin
    result_s <= signed(A) - signed(B);
    result   <= std_logic_vector(result_s);
    overflow <= (A(63) xor B(63)) and (A(63) xor result_s(63));
end Behavioral;
