library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_8bit is
    port (
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end adder_8bit;

architecture rtl of adder_8bit is
    signal c : std_logic_vector(8 downto 0);
begin
    c(0) <= cin;
    cout <= c(8);

    sum(0) <= a(0) xor b(0) xor c(0);
    c(1)   <= (a(0) and b(0)) or (a(0) and c(0)) or (b(0) and c(0));

    sum(1) <= a(1) xor b(1) xor c(1);
    c(2)   <= (a(1) and b(1)) or (a(1) and c(1)) or (b(1) and c(1));

    sum(2) <= a(2) xor b(2) xor c(2);
    c(3)   <= (a(2) and b(2)) or (a(2) and c(2)) or (b(2) and c(2));

    sum(3) <= a(3) xor b(3) xor c(3);
    c(4)   <= (a(3) and b(3)) or (a(3) and c(3)) or (b(3) and c(3));

    sum(4) <= a(4) xor b(4) xor c(4);
    c(5)   <= (a(4) and b(4)) or (a(4) and c(4)) or (b(4) and c(4));

    sum(5) <= a(5) xor b(5) xor c(5);
    c(6)   <= (a(5) and b(5)) or (a(5) and c(5)) or (b(5) and c(5));

    sum(6) <= a(6) xor b(6) xor c(6);
    c(7)   <= (a(6) and b(6)) or (a(6) and c(6)) or (b(6) and c(6));

    sum(7) <= a(7) xor b(7) xor c(7);
    c(8)   <= (a(7) and b(7)) or (a(7) and c(7)) or (b(7) and c(7));
end rtl;
