library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_low_area is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (16 downto 0)
    );
end add_low_area;

architecture rtl of add_low_area is
    signal carry : STD_LOGIC_VECTOR (16 downto 0);
begin
    carry(0) <= '0';

    gen_full_adders : for i in 0 to 15 generate
        result(i) <= a(i) xor b(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or
                        (a(i) and carry(i)) or
                        (b(i) and carry(i));
    end generate gen_full_adders;

    result(16) <= carry(16);
end rtl;
