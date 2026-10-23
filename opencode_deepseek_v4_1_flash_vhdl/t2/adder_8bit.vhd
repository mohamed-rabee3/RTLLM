library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    port (
        a    : in  std_logic;
        b    : in  std_logic;
        cin  : in  std_logic;
        sum  : out std_logic;
        cout : out std_logic
    );
end full_adder;

architecture rtl of full_adder is
begin
    sum  <= a xor b xor cin;
    cout <= (a and b) or (a and cin) or (b and cin);
end rtl;

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
    component full_adder is
        port (
            a    : in  std_logic;
            b    : in  std_logic;
            cin  : in  std_logic;
            sum  : out std_logic;
            cout : out std_logic
        );
    end component;

    signal carry : std_logic_vector(0 to 8);
begin
    carry(0) <= cin;
    cout <= carry(8);

    gen_full_adders : for i in 0 to 7 generate
        fa : full_adder
            port map (
                a    => a(i),
                b    => b(i),
                cin  => carry(i),
                sum  => sum(i),
                cout => carry(i + 1)
            );
    end generate gen_full_adders;
end rtl;
