library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_32bit is
    Port ( A : in STD_LOGIC_VECTOR(32 downto 1);
           B : in STD_LOGIC_VECTOR(32 downto 1);
           S : out STD_LOGIC_VECTOR(32 downto 1);
           C32 : out STD_LOGIC);
end adder_32bit;

architecture structural of adder_32bit is
    component cla_16bit
        Port ( A : in STD_LOGIC_VECTOR(16 downto 1);
               B : in STD_LOGIC_VECTOR(16 downto 1);
               Cin : in STD_LOGIC;
               S : out STD_LOGIC_VECTOR(16 downto 1);
               Cout : out STD_LOGIC);
    end component;

    signal C16 : STD_LOGIC;
    signal S_low : STD_LOGIC_VECTOR(16 downto 1);
    signal S_high : STD_LOGIC_VECTOR(16 downto 1);
begin
    U_low: cla_16bit
        port map (
            A => A(16 downto 1),
            B => B(16 downto 1),
            Cin => '0',
            S => S_low,
            Cout => C16
        );

    U_high: cla_16bit
        port map (
            A => A(32 downto 17),
            B => B(32 downto 17),
            Cin => C16,
            S => S_high,
            Cout => C32
        );

    S(16 downto 1) <= S_low;
    S(32 downto 17) <= S_high;
end structural;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla_16bit is
    Port ( A : in STD_LOGIC_VECTOR(16 downto 1);
           B : in STD_LOGIC_VECTOR(16 downto 1);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR(16 downto 1);
           Cout : out STD_LOGIC);
end cla_16bit;

architecture rtl of cla_16bit is
    signal G, P : STD_LOGIC_VECTOR(16 downto 1);
    signal C : STD_LOGIC_VECTOR(17 downto 1);
    signal GG0, GG1, GG2, GG3 : STD_LOGIC;
    signal GP0, GP1, GP2, GP3 : STD_LOGIC;
begin
    G <= A and B;
    P <= A xor B;

    -- Group generate/propagate for 4-bit groups
    GG0 <= G(4) or (P(4) and G(3)) or (P(4) and P(3) and G(2)) or (P(4) and P(3) and P(2) and G(1));
    GP0 <= P(4) and P(3) and P(2) and P(1);

    GG1 <= G(8) or (P(8) and G(7)) or (P(8) and P(7) and G(6)) or (P(8) and P(7) and P(6) and G(5));
    GP1 <= P(8) and P(7) and P(6) and P(5);

    GG2 <= G(12) or (P(12) and G(11)) or (P(12) and P(11) and G(10)) or (P(12) and P(11) and P(10) and G(9));
    GP2 <= P(12) and P(11) and P(10) and P(9);

    GG3 <= G(16) or (P(16) and G(15)) or (P(16) and P(15) and G(14)) or (P(16) and P(15) and P(14) and G(13));
    GP3 <= P(16) and P(15) and P(14) and P(13);

    -- Group carries
    C(1) <= Cin;
    C(5) <= GG0 or (GP0 and C(1));
    C(9) <= GG1 or (GP1 and GG0) or (GP1 and GP0 and C(1));
    C(13) <= GG2 or (GP2 and GG1) or (GP2 and GP1 and GG0) or (GP2 and GP1 and GP0 and C(1));
    C(17) <= GG3 or (GP3 and GG2) or (GP3 and GP2 and GG1) or (GP3 and GP2 and GP1 and GG0) or (GP3 and GP2 and GP1 and GP0 and C(1));

    -- Bit carries within groups
    -- Group 0 (bits 1-4)
    C(2) <= G(1) or (P(1) and C(1));
    C(3) <= G(2) or (P(2) and G(1)) or (P(2) and P(1) and C(1));
    C(4) <= G(3) or (P(3) and G(2)) or (P(3) and P(2) and G(1)) or (P(3) and P(2) and P(1) and C(1));

    -- Group 1 (bits 5-8)
    C(6) <= G(5) or (P(5) and C(5));
    C(7) <= G(6) or (P(6) and G(5)) or (P(6) and P(5) and C(5));
    C(8) <= G(7) or (P(7) and G(6)) or (P(7) and P(6) and G(5)) or (P(7) and P(6) and P(5) and C(5));

    -- Group 2 (bits 9-12)
    C(10) <= G(9) or (P(9) and C(9));
    C(11) <= G(10) or (P(10) and G(9)) or (P(10) and P(9) and C(9));
    C(12) <= G(11) or (P(11) and G(10)) or (P(11) and P(10) and G(9)) or (P(11) and P(10) and P(9) and C(9));

    -- Group 3 (bits 13-16)
    C(14) <= G(13) or (P(13) and C(13));
    C(15) <= G(14) or (P(14) and G(13)) or (P(14) and P(13) and C(13));
    C(16) <= G(15) or (P(15) and G(14)) or (P(15) and P(14) and G(13)) or (P(15) and P(14) and P(13) and C(13));

    S <= P xor C(16 downto 1);
    Cout <= C(17);
end rtl;
