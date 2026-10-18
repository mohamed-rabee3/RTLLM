library ieee;
use ieee.std_logic_1164.all;

entity adder_8bit is
    port (
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder_8bit;

architecture rtl of adder_8bit is
    signal carry : std_logic_vector(8 downto 0);
begin
    carry(0) <= cin;

    full_adders : for i in 0 to 7 generate
        sum(i) <= a(i) xor b(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or
                        (a(i) and carry(i)) or
                        (b(i) and carry(i));
    end generate full_adders;

    cout <= carry(8);
end architecture rtl;
