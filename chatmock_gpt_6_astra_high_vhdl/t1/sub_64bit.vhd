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
end entity sub_64bit;

architecture RTL of sub_64bit is
    signal difference : std_logic_vector(63 downto 0);
begin
    difference <= std_logic_vector(signed(A) - signed(B));

    result <= difference;

    overflow <= (A(63) xor B(63)) and
                (difference(63) xor A(63));
end architecture RTL;
