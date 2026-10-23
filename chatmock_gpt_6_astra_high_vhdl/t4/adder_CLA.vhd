library ieee;
use ieee.std_logic_1164.all;

entity add_CLA is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add_CLA;

architecture rtl of add_CLA is
    signal g : std_logic_vector(15 downto 0);
    signal p : std_logic_vector(15 downto 0);
    signal c : std_logic_vector(16 downto 0);
begin
    g <= a and b;
    p <= a xor b;

    c(0) <= '0';

    gen_bits : for i in 0 to 15 generate
        c(i + 1) <= g(i) or (p(i) and c(i));
        result(i) <= p(i) xor c(i);
    end generate gen_bits;

    result(16) <= c(16);
end architecture rtl;
