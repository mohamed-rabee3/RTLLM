library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_CLA is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (16 downto 0)
    );
end add_CLA;

architecture RTL of add_CLA is
    signal g : STD_LOGIC_VECTOR(15 downto 0);
    signal p : STD_LOGIC_VECTOR(15 downto 0);
    signal c : STD_LOGIC_VECTOR(16 downto 0);
begin
    g <= a and b;
    p <= a xor b;

    c(0) <= '0';

    c(1)  <= g(0)  or (p(0)  and c(0));
    c(2)  <= g(1)  or (p(1)  and c(1));
    c(3)  <= g(2)  or (p(2)  and c(2));
    c(4)  <= g(3)  or (p(3)  and c(3));
    c(5)  <= g(4)  or (p(4)  and c(4));
    c(6)  <= g(5)  or (p(5)  and c(5));
    c(7)  <= g(6)  or (p(6)  and c(6));
    c(8)  <= g(7)  or (p(7)  and c(7));
    c(9)  <= g(8)  or (p(8)  and c(8));
    c(10) <= g(9)  or (p(9)  and c(9));
    c(11) <= g(10) or (p(10) and c(10));
    c(12) <= g(11) or (p(11) and c(11));
    c(13) <= g(12) or (p(12) and c(12));
    c(14) <= g(13) or (p(13) and c(13));
    c(15) <= g(14) or (p(14) and c(14));
    c(16) <= g(15) or (p(15) and c(15));

    result <= c(16) & (p xor c(15 downto 0));
end RTL;
