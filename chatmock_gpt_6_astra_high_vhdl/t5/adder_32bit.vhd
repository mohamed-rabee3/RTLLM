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
    type prefix_array is array (0 to 4) of
        std_logic_vector(16 downto 1);

    signal p : prefix_array;
    signal g : prefix_array;
    signal c : std_logic_vector(16 downto 0);
begin
    p(0) <= A xor B;
    g(0) <= A and B;

    -- Parallel-prefix carry-lookahead network.
    gen_stages : for stage in 1 to 4 generate
        gen_bits : for i in 1 to 16 generate
            gen_combine : if i > 2**(stage - 1) generate
                g(stage)(i) <=
                    g(stage - 1)(i) or
                    (p(stage - 1)(i) and
                     g(stage - 1)(i - 2**(stage - 1)));

                p(stage)(i) <=
                    p(stage - 1)(i) and
                    p(stage - 1)(i - 2**(stage - 1));
            end generate gen_combine;

            gen_pass : if i <= 2**(stage - 1) generate
                g(stage)(i) <= g(stage - 1)(i);
                p(stage)(i) <= p(stage - 1)(i);
            end generate gen_pass;
        end generate gen_bits;
    end generate gen_stages;

    c(0) <= Cin;

    gen_sum_and_carry : for i in 1 to 16 generate
        c(i) <= g(4)(i) or (p(4)(i) and Cin);
        S(i) <= p(0)(i) xor c(i - 1);
    end generate gen_sum_and_carry;

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
end architecture rtl;
