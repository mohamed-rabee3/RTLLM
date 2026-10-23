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
    signal p : std_logic_vector(16 downto 1);
    signal g : std_logic_vector(16 downto 1);
    signal c : std_logic_vector(16 downto 0);
begin
    p <= A xor B;
    g <= A and B;

    -- Compute each carry directly from generate/propagate terms,
    -- without depending on any preceding computed carry.
    carry_lookahead : process(p, g, Cin)
        variable carries       : std_logic_vector(16 downto 0);
        variable propagate_all : std_logic;
        variable generate_any  : std_logic;
    begin
        carries(0) := Cin;

        for i in 1 to 16 loop
            propagate_all := '1';
            generate_any  := '0';

            for j in i downto 1 loop
                generate_any  := generate_any or (propagate_all and g(j));
                propagate_all := propagate_all and p(j);
            end loop;

            carries(i) := generate_any or (propagate_all and Cin);
        end loop;

        c <= carries;
    end process carry_lookahead;

    sum_bits : for i in 1 to 16 generate
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

architecture rtl of adder_32bit is
    signal c16 : std_logic;
begin
    lower_cla : entity work.cla_16bit(rtl)
        port map (
            A    => A(16 downto 1),
            B    => B(16 downto 1),
            Cin  => '0',
            S    => S(16 downto 1),
            Cout => c16
        );

    upper_cla : entity work.cla_16bit(rtl)
        port map (
            A    => A(32 downto 17),
            B    => B(32 downto 17),
            Cin  => c16,
            S    => S(32 downto 17),
            Cout => C32
        );
end architecture rtl;
