library ieee;
use ieee.std_logic_1164.all;

entity add_low_power is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add_low_power;

architecture rtl of add_low_power is
    signal carry : std_logic_vector(16 downto 0);
    signal propagate : std_logic_vector(15 downto 0);
begin
    carry(0) <= '0';

    gen_adder : for i in 0 to 15 generate
        propagate(i) <= a(i) xor b(i);
        result(i)    <= propagate(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or
                        (propagate(i) and carry(i));
    end generate gen_adder;

    result(16) <= carry(16);
end architecture rtl;
