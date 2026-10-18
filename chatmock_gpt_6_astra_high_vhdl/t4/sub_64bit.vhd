library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sub_64bit is
    port (
        A        : in  std_logic_vector(63 downto 0);
        B        : in  std_logic_vector(63 downto 0);
        result   : out std_logic_vector(63 downto 0);
        overflow : out std_logic
    );
end entity sub_64bit;

architecture rtl of sub_64bit is
    signal difference : signed(63 downto 0);
begin
    difference <= signed(A) - signed(B);

    result <= std_logic_vector(difference);

    overflow <= (A(63) xor B(63)) and
                (A(63) xor difference(63));
end architecture rtl;
