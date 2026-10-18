library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_CLA is
    port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(16 downto 0)
    );
end entity add_CLA;

architecture RTL of add_CLA is
    signal g : STD_LOGIC_VECTOR(15 downto 0);
    signal p : STD_LOGIC_VECTOR(15 downto 0);
    signal c : STD_LOGIC_VECTOR(16 downto 0);
begin
    g <= a and b;
    p <= a xor b;

    c(0) <= '0';

    gen_bits : for i in 0 to 15 generate
        c(i + 1) <= g(i) or (p(i) and c(i));
        result(i) <= p(i) xor c(i);
    end generate gen_bits;

    result(16) <= c(16);
end architecture RTL;
