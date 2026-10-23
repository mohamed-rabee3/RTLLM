library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_8bit is
    Port (
        a    : in  STD_LOGIC_VECTOR (7 downto 0);
        b    : in  STD_LOGIC_VECTOR (7 downto 0);
        cin  : in  STD_LOGIC;
        sum  : out STD_LOGIC_VECTOR (7 downto 0);
        cout : out STD_LOGIC
    );
end adder_8bit;

architecture rtl of adder_8bit is
    signal carry : STD_LOGIC_VECTOR (8 downto 0);
begin
    carry(0) <= cin;

    gen_full_adders : for i in 0 to 7 generate
        sum(i)     <= a(i) xor b(i) xor carry(i);
        carry(i+1) <= (a(i) and b(i)) or
                      (a(i) and carry(i)) or
                      (b(i) and carry(i));
    end generate gen_full_adders;

    cout <= carry(8);
end rtl;
