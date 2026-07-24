library ieee;
use ieee.std_logic_1164.all;
entity verified_add_CLA is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(16 downto 0));
end verified_add_CLA;
architecture rtl of verified_add_CLA is
    signal g, p : std_logic_vector(15 downto 0);
    signal c    : std_logic_vector(16 downto 0);
begin
    g <= a and b;
    p <= a xor b;
    c(0) <= '0';
    gen : for i in 0 to 15 generate
        c(i+1) <= g(i) or (p(i) and c(i));
    end generate;
    result(15 downto 0) <= p xor c(15 downto 0);
    result(16) <= c(16);
end rtl;
