library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla_4 is
    port (
        A    : in  std_logic_vector(3 downto 0);
        B    : in  std_logic_vector(3 downto 0);
        Cin  : in  std_logic;
        S    : out std_logic_vector(3 downto 0);
        Cout : out std_logic
    );
end cla_4;

architecture rtl of cla_4 is
    signal P : std_logic_vector(3 downto 0);
    signal G : std_logic_vector(3 downto 0);
    signal C : std_logic_vector(4 downto 0);
begin
    P <= A xor B;
    G <= A and B;

    C(0) <= Cin;

    C(1) <= G(0) or (P(0) and C(0));

    C(2) <= G(1) or (P(1) and G(0)) or
            (P(1) and P(0) and C(0));

    C(3) <= G(2) or (P(2) and G(1)) or
            (P(2) and P(1) and G(0)) or
            (P(2) and P(1) and P(0) and C(0));

    C(4) <= G(3) or (P(3) and G(2)) or
            (P(3) and P(2) and G(1)) or
            (P(3) and P(2) and P(1) and G(0)) or
            (P(3) and P(2) and P(1) and P(0) and C(0));

    S(0) <= P(0) xor C(0);
    S(1) <= P(1) xor C(1);
    S(2) <= P(2) xor C(2);
    S(3) <= P(3) xor C(3);
    Cout <= C(4);
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla_16 is
    port (
        A    : in  std_logic_vector(15 downto 0);
        B    : in  std_logic_vector(15 downto 0);
        Cin  : in  std_logic;
        S    : out std_logic_vector(15 downto 0);
        Cout : out std_logic
    );
end cla_16;

architecture structural of cla_16 is
    signal P  : std_logic_vector(15 downto 0);
    signal G  : std_logic_vector(15 downto 0);
    signal PG : std_logic_vector(3 downto 0);
    signal GG : std_logic_vector(3 downto 0);
    signal CG : std_logic_vector(4 downto 0);
begin
    P <= A xor B;
    G <= A and B;

    PG(0) <= P(3) and P(2) and P(1) and P(0);
    GG(0) <= G(3) or (P(3) and G(2)) or
             (P(3) and P(2) and G(1)) or
             (P(3) and P(2) and P(1) and G(0));

    PG(1) <= P(7) and P(6) and P(5) and P(4);
    GG(1) <= G(7) or (P(7) and G(6)) or
             (P(7) and P(6) and G(5)) or
             (P(7) and P(6) and P(5) and G(4));

    PG(2) <= P(11) and P(10) and P(9) and P(8);
    GG(2) <= G(11) or (P(11) and G(10)) or
             (P(11) and P(10) and G(9)) or
             (P(11) and P(10) and P(9) and G(8));

    PG(3) <= P(15) and P(14) and P(13) and P(12);
    GG(3) <= G(15) or (P(15) and G(14)) or
             (P(15) and P(14) and G(13)) or
             (P(15) and P(14) and P(13) and G(12));

    CG(0) <= Cin;

    CG(1) <= GG(0) or (PG(0) and CG(0));

    CG(2) <= GG(1) or (PG(1) and GG(0)) or
             (PG(1) and PG(0) and CG(0));

    CG(3) <= GG(2) or (PG(2) and GG(1)) or
             (PG(2) and PG(1) and GG(0)) or
             (PG(2) and PG(1) and PG(0) and CG(0));

    CG(4) <= GG(3) or (PG(3) and GG(2)) or
             (PG(3) and PG(2) and GG(1)) or
             (PG(3) and PG(2) and PG(1) and GG(0)) or
             (PG(3) and PG(2) and PG(1) and PG(0) and CG(0));

    Cout <= CG(4);

    u0: entity work.cla_4
        port map (
            A    => A(3 downto 0),
            B    => B(3 downto 0),
            Cin  => CG(0),
            S    => S(3 downto 0),
            Cout => open
        );

    u1: entity work.cla_4
        port map (
            A    => A(7 downto 4),
            B    => B(7 downto 4),
            Cin  => CG(1),
            S    => S(7 downto 4),
            Cout => open
        );

    u2: entity work.cla_4
        port map (
            A    => A(11 downto 8),
            B    => B(11 downto 8),
            Cin  => CG(2),
            S    => S(11 downto 8),
            Cout => open
        );

    u3: entity work.cla_4
        port map (
            A    => A(15 downto 12),
            B    => B(15 downto 12),
            Cin  => CG(3),
            S    => S(15 downto 12),
            Cout => open
        );
end structural;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_32bit is
    port (
        A   : in  std_logic_vector(32 downto 1);
        B   : in  std_logic_vector(32 downto 1);
        S   : out std_logic_vector(32 downto 1);
        C32 : out std_logic
    );
end adder_32bit;

architecture structural of adder_32bit is
    signal carry_mid : std_logic;
begin
    u_low: entity work.cla_16
        port map (
            A    => A(16 downto 1),
            B    => B(16 downto 1),
            Cin  => '0',
            S    => S(16 downto 1),
            Cout => carry_mid
        );

    u_high: entity work.cla_16
        port map (
            A    => A(32 downto 17),
            B    => B(32 downto 17),
            Cin  => carry_mid,
            S    => S(32 downto 17),
            Cout => C32
        );
end structural;
