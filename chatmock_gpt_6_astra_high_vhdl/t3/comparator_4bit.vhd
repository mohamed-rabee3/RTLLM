library ieee;
use ieee.std_logic_1164.all;

entity comparator_4bit is
    port (
        A         : in  std_logic_vector(3 downto 0);
        B         : in  std_logic_vector(3 downto 0);
        A_greater : out std_logic;
        A_equal   : out std_logic;
        A_less    : out std_logic
    );
end entity comparator_4bit;

architecture rtl of comparator_4bit is
    signal difference : std_logic_vector(3 downto 0);
    signal borrow     : std_logic_vector(4 downto 0);
    signal result_zero : std_logic;
begin
    borrow(0) <= '0';

    -- Ripple-borrow subtraction: A - B.
    subtract_bits : for i in 0 to 3 generate
        difference(i) <= A(i) xor B(i) xor borrow(i);

        borrow(i + 1) <= ((not A(i)) and B(i)) or
                         ((not (A(i) xor B(i))) and borrow(i));
    end generate subtract_bits;

    result_zero <= not (difference(3) or difference(2) or
                        difference(1) or difference(0));

    A_less    <= borrow(4);
    A_equal   <= (not borrow(4)) and result_zero;
    A_greater <= (not borrow(4)) and (not result_zero);
end architecture rtl;
