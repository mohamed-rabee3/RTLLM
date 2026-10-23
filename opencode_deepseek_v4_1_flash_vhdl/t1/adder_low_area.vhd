library ieee;
use ieee.std_logic_1164.all;

entity add_low_area is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end add_low_area;

architecture rtl of add_low_area is
begin
    process(a, b)
        variable carry : std_logic;
    begin
        carry := '0';

        for i in 0 to 15 loop
            result(i) <= a(i) xor b(i) xor carry;
            carry := (a(i) and b(i)) or
                     (a(i) and carry) or
                     (b(i) and carry);
        end loop;

        result(16) <= carry;
    end process;
end rtl;
