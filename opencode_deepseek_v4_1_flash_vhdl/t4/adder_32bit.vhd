library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla16 is
    port (
        A    : in  std_logic_vector(16 downto 1);
        B    : in  std_logic_vector(16 downto 1);
        Cin  : in  std_logic;
        S    : out std_logic_vector(16 downto 1);
        Cout : out std_logic
    );
end cla16;

architecture rtl of cla16 is
    signal p : std_logic_vector(16 downto 1);
    signal g : std_logic_vector(16 downto 1);
    signal Gg : std_logic_vector(4 downto 1);
    signal Pg : std_logic_vector(4 downto 1);
    signal Cg : std_logic_vector(4 downto 0);
    signal c1, c2, c3 : std_logic;
    signal c5, c6, c7 : std_logic;
    signal c9, c10, c11 : std_logic;
    signal c13, c14, c15 : std_logic;
begin
    gen_bits: for i in 1 to 16 generate
        p(i) <= A(i) xor B(i);
        g(i) <= A(i) and B(i);
    end generate;

    -- Group generate and propagate (4-bit groups)
    -- Group 1: bits 1-4
    Gg(1) <= g(4) or (p(4) and g(3)) or (p(4) and p(3) and g(2)) or (p(4) and p(3) and p(2) and g(1));
    Pg(1) <= p(4) and p(3) and p(2) and p(1);
    -- Group 2: bits 5-8
    Gg(2) <= g(8) or (p(8) and g(7)) or (p(8) and p(7) and g(6)) or (p(8) and p(7) and p(6) and g(5));
    Pg(2) <= p(8) and p(7) and p(6) and p(5);
    -- Group 3: bits 9-12
    Gg(3) <= g(12) or (p(12) and g(11)) or (p(12) and p(11) and g(10)) or (p(12) and p(11) and p(10) and g(9));
    Pg(3) <= p(12) and p(11) and p(10) and p(9);
    -- Group 4: bits 13-16
    Gg(4) <= g(16) or (p(16) and g(15)) or (p(16) and p(15) and g(14)) or (p(16) and p(15) and p(14) and g(13));
    Pg(4) <= p(16) and p(15) and p(14) and p(13);

    -- Group carries
    Cg(0) <= Cin;
    Cg(1) <= Gg(1) or (Pg(1) and Cg(0));
    Cg(2) <= Gg(2) or (Pg(2) and Gg(1)) or (Pg(2) and Pg(1) and Cg(0));
    Cg(3) <= Gg(3) or (Pg(3) and Gg(2)) or (Pg(3) and Pg(2) and Gg(1)) or (Pg(3) and Pg(2) and Pg(1) and Cg(0));
    Cg(4) <= Gg(4) or (Pg(4) and Gg(3)) or (Pg(4) and Pg(3) and Gg(2)) or (Pg(4) and Pg(3) and Pg(2) and Gg(1)) or (Pg(4) and Pg(3) and Pg(2) and Pg(1) and Cg(0));

    -- Internal carries for bits
    c1 <= g(1) or (p(1) and Cg(0));
    c2 <= g(2) or (p(2) and g(1)) or (p(2) and p(1) and Cg(0));
    c3 <= g(3) or (p(3) and g(2)) or (p(3) and p(2) and g(1)) or (p(3) and p(2) and p(1) and Cg(0));

    c5 <= g(5) or (p(5) and Cg(1));
    c6 <= g(6) or (p(6) and g(5)) or (p(6) and p(5) and Cg(1));
    c7 <= g(7) or (p(7) and g(6)) or (p(7) and p(6) and g(5)) or (p(7) and p(6) and p(5) and Cg(1));

    c9 <= g(9) or (p(9) and Cg(2));
    c10 <= g(10) or (p(10) and g(9)) or (p(10) and p(9) and Cg(2));
    c11 <= g(11) or (p(11) and g(10)) or (p(11) and p(10) and g(9)) or (p(11) and p(10) and p(9) and Cg(2));

    c13 <= g(13) or (p(13) and Cg(3));
    c14 <= g(14) or (p(14) and g(13)) or (p(14) and p(13) and Cg(3));
    c15 <= g(15) or (p(15) and g(14)) or (p(15) and p(14) and g(13)) or (p(15) and p(14) and p(13) and Cg(3));

    -- Sum bits
    S(1) <= p(1) xor Cg(0);
    S(2) <= p(2) xor c1;
    S(3) <= p(3) xor c2;
    S(4) <= p(4) xor c3;
    S(5) <= p(5) xor Cg(1);
    S(6) <= p(6) xor c5;
    S(7) <= p(7) xor c6;
    S(8) <= p(8) xor c7;
    S(9) <= p(9) xor Cg(2);
    S(10) <= p(10) xor c9;
    S(11) <= p(11) xor c10;
    S(12) <= p(12) xor c11;
    S(13) <= p(13) xor Cg(3);
    S(14) <= p(14) xor c13;
    S(15) <= p(15) xor c14;
    S(16) <= p(16) xor c15;

    Cout <= Cg(4);
end rtl;

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

architecture rtl of adder_32bit is
    signal C16 : std_logic;
begin
    lower_cla: entity work.cla16
        port map (
            A    => A(16 downto 1),
            B    => B(16 downto 1),
            Cin  => '0',
            S    => S(16 downto 1),
            Cout => C16
        );

    upper_cla: entity work.cla16
        port map (
            A    => A(32 downto 17),
            B    => B(32 downto 17),
            Cin  => C16,
            S    => S(32 downto 17),
            Cout => C32
        );
end rtl;
