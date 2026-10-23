library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla_16bit is
    Port (
        A    : in  std_logic_vector(15 downto 0);
        B    : in  std_logic_vector(15 downto 0);
        Cin  : in  std_logic;
        S    : out std_logic_vector(15 downto 0);
        Cout : out std_logic
    );
end cla_16bit;

architecture rtl of cla_16bit is
    signal P, G   : std_logic_vector(15 downto 0);
    signal GP, GG : std_logic_vector(3 downto 0);
    signal C      : std_logic_vector(16 downto 0);
begin
    gen_pg: for i in 0 to 15 generate
        P(i) <= A(i) xor B(i);
        G(i) <= A(i) and B(i);
    end generate gen_pg;

    GP(0) <= P(3) and P(2) and P(1) and P(0);
    GG(0) <= G(3) or (P(3) and G(2)) or (P(3) and P(2) and G(1)) or (P(3) and P(2) and P(1) and G(0));

    GP(1) <= P(7) and P(6) and P(5) and P(4);
    GG(1) <= G(7) or (P(7) and G(6)) or (P(7) and P(6) and G(5)) or (P(7) and P(6) and P(5) and G(4));

    GP(2) <= P(11) and P(10) and P(9) and P(8);
    GG(2) <= G(11) or (P(11) and G(10)) or (P(11) and P(10) and G(9)) or (P(11) and P(10) and P(9) and G(8));

    GP(3) <= P(15) and P(14) and P(13) and P(12);
    GG(3) <= G(15) or (P(15) and G(14)) or (P(15) and P(14) and G(13)) or (P(15) and P(14) and P(13) and G(12));

    C(0) <= Cin;
    C(4) <= GG(0) or (GP(0) and C(0));
    C(8) <= GG(1) or (GP(1) and C(4));
    C(12) <= GG(2) or (GP(2) and C(8));
    C(16) <= GG(3) or (GP(3) and C(12));
    Cout <= C(16);

    C(1) <= G(0) or (P(0) and C(0));
    C(2) <= G(1) or (P(1) and G(0)) or (P(1) and P(0) and C(0));
    C(3) <= G(2) or (P(2) and G(1)) or (P(2) and P(1) and G(0)) or (P(2) and P(1) and P(0) and C(0));

    C(5) <= G(4) or (P(4) and C(4));
    C(6) <= G(5) or (P(5) and G(4)) or (P(5) and P(4) and C(4));
    C(7) <= G(6) or (P(6) and G(5)) or (P(6) and P(5) and G(4)) or (P(6) and P(5) and P(4) and C(4));

    C(9) <= G(8) or (P(8) and C(8));
    C(10) <= G(9) or (P(9) and G(8)) or (P(9) and P(8) and C(8));
    C(11) <= G(10) or (P(10) and G(9)) or (P(10) and P(9) and G(8)) or (P(10) and P(9) and P(8) and C(8));

    C(13) <= G(12) or (P(12) and C(12));
    C(14) <= G(13) or (P(13) and G(12)) or (P(13) and P(12) and C(12));
    C(15) <= G(14) or (P(14) and G(13)) or (P(14) and P(13) and G(12)) or (P(14) and P(13) and P(12) and C(12));

    S <= P xor C(15 downto 0);
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_32bit is
    Port (
        A   : in  std_logic_vector(32 downto 1);
        B   : in  std_logic_vector(32 downto 1);
        S   : out std_logic_vector(32 downto 1);
        C32 : out std_logic
    );
end adder_32bit;

architecture structural of adder_32bit is
    signal C16 : std_logic;
begin
    U_low: entity work.cla_16bit
        port map (
            A    => A(16 downto 1),
            B    => B(16 downto 1),
            Cin  => '0',
            S    => S(16 downto 1),
            Cout => C16
        );

    U_high: entity work.cla_16bit
        port map (
            A    => A(32 downto 17),
            B    => B(32 downto 17),
            Cin  => C16,
            S    => S(32 downto 17),
            Cout => C32
        );
end structural;
