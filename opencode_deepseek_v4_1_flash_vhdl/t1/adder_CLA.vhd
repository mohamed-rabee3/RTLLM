library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_CLA is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (16 downto 0)
    );
end add_CLA;

architecture rtl of add_CLA is
    signal g : STD_LOGIC_VECTOR (15 downto 0);
    signal p : STD_LOGIC_VECTOR (15 downto 0);
    signal c : STD_LOGIC_VECTOR (16 downto 0);
begin
    gen_prop : for i in 0 to 15 generate
        g(i) <= a(i) and b(i);
        p(i) <= a(i) xor b(i);
    end generate gen_prop;

    c(0) <= '0';

    carry_chain : for i in 0 to 15 generate
        c(i + 1) <= g(i) or (p(i) and c(i));
    end generate carry_chain;

    sum_bits : for i in 0 to 15 generate
        result(i) <= p(i) xor c(i);
    end generate sum_bits;

    result(16) <= c(16);
end rtl;
