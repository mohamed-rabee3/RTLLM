library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_low_area is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(16 downto 0)
    );
end add_low_area;

architecture rtl of add_low_area is
begin
    process(a, b)
        variable carry      : STD_LOGIC;
        variable sum_bit    : STD_LOGIC;
        variable next_carry : STD_LOGIC;
    begin
        carry := '0';

        for i in 0 to 15 loop
            sum_bit    := a(i) xor b(i) xor carry;
            next_carry := (a(i) and b(i)) or (a(i) and carry) or (b(i) and carry);

            result(i) <= sum_bit;
            carry := next_carry;
        end loop;

        result(16) <= carry;
    end process;
end rtl;
