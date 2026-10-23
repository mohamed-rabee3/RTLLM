library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sub_64bit is
    Port (
        A        : in  STD_LOGIC_VECTOR (63 downto 0);
        B        : in  STD_LOGIC_VECTOR (63 downto 0);
        result   : out STD_LOGIC_VECTOR (63 downto 0);
        overflow : out STD_LOGIC
    );
end sub_64bit;

architecture Behavioral of sub_64bit is
    signal diff   : unsigned(63 downto 0);
    signal a_sign : std_logic;
    signal b_sign : std_logic;
    signal r_sign : std_logic;
begin
    diff <= unsigned(A) - unsigned(B);

    result <= std_logic_vector(diff);

    a_sign <= A(63);
    b_sign <= B(63);
    r_sign <= diff(63);

    overflow <= (a_sign xor b_sign) and (r_sign xor a_sign);
end Behavioral;
