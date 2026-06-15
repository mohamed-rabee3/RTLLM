library ieee;
use ieee.std_logic_1164.all;

-- 1-bit full adder
entity full_adder_1bit is
    port (
        a    : in  std_logic;
        b    : in  std_logic;
        cin  : in  std_logic;
        s    : out std_logic;
        cout : out std_logic
    );
end entity full_adder_1bit;

architecture behavioral of full_adder_1bit is
begin
    s    <= a xor b xor cin;
    cout <= (a and b) or (a and cin) or (b and cin);
end architecture behavioral;

-- 8-bit full adder built from 1-bit adders
entity adder_8bit is
    port (
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        y    : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder_8bit;

architecture structural of adder_8bit is
    signal carry : std_logic_vector(8 downto 0);
begin
    carry(0) <= cin;
    gen_full_adders : for i in 0 to 7 generate
        fa_inst : entity work.full_adder_1bit
            port map (
                a    => a(i),
                b    => b(i),
                cin  => carry(i),
                s    => y(i),
                cout => carry(i+1)
            );
    end generate;
    cout <= carry(8);
end architecture structural;

-- 16-bit full adder using two 8-bit adders
entity adder_16bit is
    port (
        a   : in  std_logic_vector(15 downto 0);
        b   : in  std_logic_vector(15 downto 0);
        Cin : in  std_logic;
        y   : out std_logic_vector(15 downto 0);
        Co  : out std_logic
    );
end entity adder_16bit;

architecture structural of adder_16bit is
    signal c8 : std_logic;  -- carry out from lower 8-bit adder
begin
    -- Lower 8 bits (a[7:0] + b[7:0] + Cin)
    low_adder : entity work.adder_8bit
        port map (
            a    => a(7 downto 0),
            b    => b(7 downto 0),
            cin  => Cin,
            y    => y(7 downto 0),
            cout => c8
        );

    -- Upper 8 bits (a[15:8] + b[15:8] + carry from lower half)
    high_adder : entity work.adder_8bit
        port map (
            a    => a(15 downto 8),
            b    => b(15 downto 8),
            cin  => c8,
            y    => y(15 downto 8),
            cout => Co
        );
end architecture structural;