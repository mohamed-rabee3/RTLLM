library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity comparator_4bit is
    port (
        A         : in  STD_LOGIC_VECTOR(3 downto 0);
        B         : in  STD_LOGIC_VECTOR(3 downto 0);
        A_greater : out STD_LOGIC;
        A_equal   : out STD_LOGIC;
        A_less    : out STD_LOGIC
    );
end entity comparator_4bit;

architecture RTL of comparator_4bit is
    signal difference : STD_LOGIC_VECTOR(3 downto 0);
    signal borrow     : STD_LOGIC_VECTOR(4 downto 0);
    signal zero_result : STD_LOGIC;
begin
    borrow(0) <= '0';

    bit_comparators : for i in 0 to 3 generate
        difference(i) <= A(i) xor B(i) xor borrow(i);

        borrow(i + 1) <= ((not A(i)) and B(i)) or
                         ((not (A(i) xor B(i))) and borrow(i));
    end generate bit_comparators;

    zero_result <= not (difference(3) or difference(2) or
                        difference(1) or difference(0));

    A_less    <= borrow(4);
    A_equal   <= (not borrow(4)) and zero_result;
    A_greater <= (not borrow(4)) and (not zero_result);
end architecture RTL;
