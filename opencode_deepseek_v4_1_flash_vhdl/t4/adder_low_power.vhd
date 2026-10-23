library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_low_power is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end add_low_power;

architecture rtl of add_low_power is
    signal carry    : std_logic_vector(16 downto 0);
    signal sum_bits : std_logic_vector(15 downto 0);
begin
    carry(0) <= '0';

    gen_ripple_adder : for i in 0 to 15 generate
        sum_bits(i) <= a(i) xor b(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or
                        (a(i) and carry(i)) or
                        (b(i) and carry(i));
    end generate gen_ripple_adder;

    result(15 downto 0) <= sum_bits;
    result(16) <= carry(16);
end rtl;
