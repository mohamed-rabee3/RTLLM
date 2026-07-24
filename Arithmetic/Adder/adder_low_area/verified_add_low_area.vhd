library ieee;
use ieee.std_logic_1164.all;
entity verified_add_low_area is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(16 downto 0));
end verified_add_low_area;
architecture rtl of verified_add_low_area is
    signal c : std_logic_vector(16 downto 0);
    signal s : std_logic_vector(15 downto 0);
begin
    c(0) <= '0';
    fa : for i in 0 to 15 generate
        s(i)   <= a(i) xor b(i) xor c(i);
        c(i+1) <= (a(i) and b(i)) or (a(i) and c(i)) or (b(i) and c(i));
    end generate;
    result <= c(16) & s;
end rtl;
