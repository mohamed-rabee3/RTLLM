library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cla_16bit is
    Port (
        A    : in  STD_LOGIC_VECTOR(16 downto 1);
        B    : in  STD_LOGIC_VECTOR(16 downto 1);
        C_in : in  STD_LOGIC;
        S    : out STD_LOGIC_VECTOR(16 downto 1);
        C_out: out STD_LOGIC
    );
end cla_16bit;

architecture rtl of cla_16bit is
    signal p : STD_LOGIC_VECTOR(16 downto 1);
    signal g : STD_LOGIC_VECTOR(16 downto 1);
    signal c : STD_LOGIC_VECTOR(16 downto 0);
    signal G0, G1, G2, G3 : STD_LOGIC;
    signal P0, P1, P2, P3 : STD_LOGIC;
begin
    p <= A xor B;
    g <= A and B;
    c(0) <= C_in;

    G0 <= g(4) or (p(4) and g(3)) or (p(4) and p(3) and g(2)) or (p(4) and p(3) and p(2) and g(1));
    P0 <= p(4) and p(3) and p(2) and p(1);
    G1 <= g(8) or (p(8) and g(7)) or (p(8) and p(7) and g(6)) or (p(8) and p(7) and p(6) and g(5));
    P1 <= p(8) and p(7) and p(6) and p(5);
    G2 <= g(12) or (p(12) and g(11)) or (p(12) and p(11) and g(10)) or (p(12) and p(11) and p(10) and g(9));
    P2 <= p(12) and p(11) and p(10) and p(9);
    G3 <= g(16) or (p(16) and g(15)) or (p(16) and p(15) and g(14)) or (p(16) and p(15) and p(14) and g(13));
    P3 <= p(16) and p(15) and p(14) and p(13);

    c(1)  <= g(1) or (p(1) and c(0));
    c(2)  <= g(2) or (p(2) and g(1)) or (p(2) and p(1) and c(0));
    c(3)  <= g(3) or (p(3) and g(2)) or (p(3) and p(2) and g(1)) or (p(3) and p(2) and p(1) and c(0));
    c(4)  <= G0 or (P0 and c(0));
    c(5)  <= g(5) or (p(5) and c(4));
    c(6)  <= g(6) or (p(6) and g(5)) or (p(6) and p(5) and c(4));
    c(7)  <= g(7) or (p(7) and g(6)) or (p(7) and p(6) and g(5)) or (p(7) and p(6) and p(5) and c(4));
    c(8)  <= G1 or (P1 and G0) or (P1 and P0 and c(0));
    c(9)  <= g(9) or (p(9) and c(8));
    c(10) <= g(10) or (p(10) and g(9)) or (p(10) and p(9) and c(8));
    c(11) <= g(11) or (p(11) and g(10)) or (p(11) and p(10) and g(9)) or (p(11) and p(10) and p(9) and c(8));
    c(12) <= G2 or (P2 and G1) or (P2 and P1 and G0) or (P2 and P1 and P0 and c(0));
    c(13) <= g(13) or (p(13) and c(12));
    c(14) <= g(14) or (p(14) and g(13)) or (p(14) and p(13) and c(12));
    c(15) <= g(15) or (p(15) and g(14)) or (p(15) and p(14) and g(13)) or (p(15) and p(14) and p(13) and c(12));
    c(16) <= G3 or (P3 and G2) or (P3 and P2 and G1) or (P3 and P2 and P1 and G0) or (P3 and P2 and P1 and P0 and c(0));

    gen_sum: for i in 1 to 16 generate
        S(i) <= p(i) xor c(i-1);
    end generate gen_sum;

    C_out <= c(16);
end rtl;

entity adder_32bit is
    Port (
        A   : in  STD_LOGIC_VECTOR(32 downto 1);
        B   : in  STD_LOGIC_VECTOR(32 downto 1);
        S   : out STD_LOGIC_VECTOR(32 downto 1);
        C32 : out STD_LOGIC
    );
end adder_32bit;

architecture rtl of adder_32bit is
    signal c16     : STD_LOGIC;
    signal S_lower : STD_LOGIC_VECTOR(16 downto 1);
    signal S_upper : STD_LOGIC_VECTOR(16 downto 1);
begin
    u_cla_lower: entity work.cla_16bit
        port map (
            A     => A(16 downto 1),
            B     => B(16 downto 1),
            C_in  => '0',
            S     => S_lower,
            C_out => c16
        );

    u_cla_upper: entity work.cla_16bit
        port map (
            A     => A(32 downto 17),
            B     => B(32 downto 17),
            C_in  => c16,
            S     => S_upper,
            C_out => C32
        );

    S(16 downto 1)  <= S_lower;
    S(32 downto 17) <= S_upper;
end rtl;
