library IEEE;
use IEEE.std_logic_1164.all;

-- 4-bit carry-lookahead block
entity cla_4bit is
    port (
        A   : in  std_logic_vector(3 downto 0);
        B   : in  std_logic_vector(3 downto 0);
        Cin : in  std_logic;
        S   : out std_logic_vector(3 downto 0);
        P   : out std_logic;             -- Group propagate
        G   : out std_logic              -- Group generate
    );
end cla_4bit;

architecture rtl of cla_4bit is
    signal p, g : std_logic_vector(3 downto 0);
    signal c    : std_logic_vector(4 downto 0); -- c(0) = Cin, c(4) unused
begin
    -- Compute bitwise propagate and generate
    p <= A xor B;
    g <= A and B;

    -- Carry lookahead inside the 4-bit block
    c(0) <= Cin;
    c(1) <= g(0) or (p(0) and Cin);
    c(2) <= g(1) or (p(1) and g(0)) or (p(1) and p(0) and Cin);
    c(3) <= g(2) or (p(2) and g(1)) or (p(2) and p(1) and g(0)) or
            (p(2) and p(1) and p(0) and Cin);
    c(4) <= g(3) or (p(3) and g(2)) or (p(3) and p(2) and g(1)) or
            (p(3) and p(2) and p(1) and g(0)) or
            (p(3) and p(2) and p(1) and p(0) and Cin);

    -- Sum bits
    S <= p xor c(3 downto 0);

    -- Group propagate and generate
    P <= p(3) and p(2) and p(1) and p(0);
    G <= g(3) or (p(3) and g(2)) or (p(3) and p(2) and g(1)) or
         (p(3) and p(2) and p(1) and g(0));
end rtl;

-- 4-bit carry-lookahead generator (for grouping four 4-bit CLA blocks)
entity carry_lookahead_4 is
    port (
        Cin : in  std_logic;
        P   : in  std_logic_vector(3 downto 0);  -- group propagates
        G   : in  std_logic_vector(3 downto 0);  -- group generates
        C   : out std_logic_vector(4 downto 1)   -- C4, C8, C12, C16
    );
end carry_lookahead_4;

architecture rtl of carry_lookahead_4 is
begin
    C(1) <= G(0) or (P(0) and Cin);
    C(2) <= G(1) or (P(1) and G(0)) or (P(1) and P(0) and Cin);
    C(3) <= G(2) or (P(2) and G(1)) or (P(2) and P(1) and G(0)) or
            (P(2) and P(1) and P(0) and Cin);
    C(4) <= G(3) or (P(3) and G(2)) or (P(3) and P(2) and G(1)) or
            (P(3) and P(2) and P(1) and G(0)) or
            (P(3) and P(2) and P(1) and P(0) and Cin);
end rtl;

-- 16-bit carry-lookahead adder built from four 4-bit CLA blocks
entity cla_16bit is
    port (
        A   : in  std_logic_vector(15 downto 0);
        B   : in  std_logic_vector(15 downto 0);
        Cin : in  std_logic;
        S   : out std_logic_vector(15 downto 0);
        Cout: out std_logic
    );
end cla_16bit;

architecture structural of cla_16bit is
    signal P_grp, G_grp : std_logic_vector(3 downto 0);
    signal C_grp        : std_logic_vector(4 downto 1); -- C4, C8, C12, C16
begin
    -- Four 4-bit CLA blocks
    CLA0: entity work.cla_4bit
        port map (
            A   => A(3 downto 0),
            B   => B(3 downto 0),
            Cin => Cin,
            S   => S(3 downto 0),
            P   => P_grp(0),
            G   => G_grp(0)
        );

    CLA1: entity work.cla_4bit
        port map (
            A   => A(7 downto 4),
            B   => B(7 downto 4),
            Cin => C_grp(1),
            S   => S(7 downto 4),
            P   => P_grp(1),
            G   => G_grp(1)
        );

    CLA2: entity work.cla_4bit
        port map (
            A   => A(11 downto 8),
            B   => B(11 downto 8),
            Cin => C_grp(2),
            S   => S(11 downto 8),
            P   => P_grp(2),
            G   => G_grp(2)
        );

    CLA3: entity work.cla_4bit
        port map (
            A   => A(15 downto 12),
            B   => B(15 downto 12),
            Cin => C_grp(3),
            S   => S(15 downto 12),
            P   => P_grp(3),
            G   => G_grp(3)
        );

    -- Carry lookahead across the four groups
    CLU: entity work.carry_lookahead_4
        port map (
            Cin => Cin,
            P   => P_grp,
            G   => G_grp,
            C   => C_grp
        );

    Cout <= C_grp(4);
end structural;

-- Top-level 32-bit adder using two 16-bit CLA blocks
entity adder_32bit is
    port (
        A   : in  std_logic_vector(32 downto 1);
        B   : in  std_logic_vector(32 downto 1);
        S   : out std_logic_vector(32 downto 1);
        C32 : out std_logic
    );
end adder_32bit;

architecture structural of adder_32bit is
    signal A_int, B_int, S_int : std_logic_vector(31 downto 0);
    signal C16 : std_logic;
begin
    -- Convert 1-based ports to 0-based internal vectors
    A_int <= A;
    B_int <= B;
    S     <= S_int;

    -- Lower 16 bits (bits 1 to 16)
    CLA_LO: entity work.cla_16bit
        port map (
            A   => A_int(15 downto 0),
            B   => B_int(15 downto 0),
            Cin => '0',
            S   => S_int(15 downto 0),
            Cout=> C16
        );

    -- Upper 16 bits (bits 17 to 32)
    CLA_HI: entity work.cla_16bit
        port map (
            A   => A_int(31 downto 16),
            B   => B_int(31 downto 16),
            Cin => C16,
            S   => S_int(31 downto 16),
            Cout=> C32
        );
end structural;