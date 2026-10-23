library ieee;
use ieee.std_logic_1164.all;

entity cla_16bit is
    port (
        A    : in  std_logic_vector(16 downto 1);
        B    : in  std_logic_vector(16 downto 1);
        Cin  : in  std_logic;
        S    : out std_logic_vector(16 downto 1);
        Cout : out std_logic
    );
end entity cla_16bit;

architecture rtl of cla_16bit is
    signal p, g   : std_logic_vector(16 downto 1);
    signal gp, gg : std_logic_vector(3 downto 0);
    signal c      : std_logic_vector(16 downto 0);
begin
    p <= A xor B;
    g <= A and B;

    c(0) <= Cin;

    -- Four-bit group propagate and generate functions.
    groups : for k in 0 to 3 generate
        constant base : integer := 4 * k;
    begin
        gp(k) <= p(base + 4) and p(base + 3)
                 and p(base + 2) and p(base + 1);

        gg(k) <= g(base + 4)
                 or (p(base + 4) and g(base + 3))
                 or (p(base + 4) and p(base + 3) and g(base + 2))
                 or (p(base + 4) and p(base + 3)
                     and p(base + 2) and g(base + 1));

        -- Lookahead carries within each four-bit group.
        c(base + 1) <= g(base + 1)
                       or (p(base + 1) and c(base));

        c(base + 2) <= g(base + 2)
                       or (p(base + 2) and g(base + 1))
                       or (p(base + 2) and p(base + 1) and c(base));

        c(base + 3) <= g(base + 3)
                       or (p(base + 3) and g(base + 2))
                       or (p(base + 3) and p(base + 2)
                           and g(base + 1))
                       or (p(base + 3) and p(base + 2)
                           and p(base + 1) and c(base));
    end generate groups;

    -- Second-level lookahead for the four group boundaries.
    c(4) <= gg(0)
            or (gp(0) and c(0));

    c(8) <= gg(1)
            or (gp(1) and gg(0))
            or (gp(1) and gp(0) and c(0));

    c(12) <= gg(2)
             or (gp(2) and gg(1))
             or (gp(2) and gp(1) and gg(0))
             or (gp(2) and gp(1) and gp(0) and c(0));

    c(16) <= gg(3)
             or (gp(3) and gg(2))
             or (gp(3) and gp(2) and gg(1))
             or (gp(3) and gp(2) and gp(1) and gg(0))
             or (gp(3) and gp(2) and gp(1) and gp(0) and c(0));

    sum_bits : for i in 1 to 16 generate
    begin
        S(i) <= p(i) xor c(i - 1);
    end generate sum_bits;

    Cout <= c(16);
end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;

entity adder_32bit is
    port (
        A   : in  std_logic_vector(32 downto 1);
        B   : in  std_logic_vector(32 downto 1);
        S   : out std_logic_vector(32 downto 1);
        C32 : out std_logic
    );
end entity adder_32bit;

architecture structural of adder_32bit is
    signal carry16 : std_logic;
begin
    lower_cla : entity work.cla_16bit(rtl)
        port map (
            A    => A(16 downto 1),
            B    => B(16 downto 1),
            Cin  => '0',
            S    => S(16 downto 1),
            Cout => carry16
        );

    upper_cla : entity work.cla_16bit(rtl)
        port map (
            A    => A(32 downto 17),
            B    => B(32 downto 17),
            Cin  => carry16,
            S    => S(32 downto 17),
            Cout => C32
        );
end architecture structural;
