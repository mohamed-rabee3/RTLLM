library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sub_64bit is
    port (
        A        : in  std_logic_vector(63 downto 0);
        B        : in  std_logic_vector(63 downto 0);
        result   : out std_logic_vector(63 downto 0);
        overflow : out std_logic
    );
end sub_64bit;

architecture behavioral of sub_64bit is
    signal diff_signed : signed(63 downto 0);
    signal sign_A, sign_B, sign_R : std_logic;
begin
    -- Perform signed subtraction
    diff_signed <= signed(A) - signed(B);
    result      <= std_logic_vector(diff_signed);

    -- Extract sign bits
    sign_A <= A(63);
    sign_B <= B(63);
    sign_R <= diff_signed(63);

    -- Overflow detection:
    -- Positive overflow: A positive, B negative, result negative
    -- Negative overflow: A negative, B positive, result positive
    overflow <= '1' when (sign_A = '0' and sign_B = '1' and sign_R = '1') or
                         (sign_A = '1' and sign_B = '0' and sign_R = '0')
                else '0';
end behavioral;