library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_adder is
    generic (
        Q : natural  := 15;
        N : positive := 32
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end entity fixed_point_adder;

architecture rtl of fixed_point_adder is
    signal res : std_logic_vector(N-1 downto 0);
begin
    -- Sign-magnitude operands share the same Q-bit fractional scale.
    -- Magnitude overflow is discarded; the sign bit is assigned separately.
    process(a, b)
        variable mag_a      : unsigned(N-1 downto 0);
        variable mag_b      : unsigned(N-1 downto 0);
        variable magnitude : unsigned(N-1 downto 0);
        variable sign_bit  : std_logic;
        variable result_v  : std_logic_vector(N-1 downto 0);
    begin
        mag_a := unsigned(a);
        mag_b := unsigned(b);
        mag_a(N-1) := '0';
        mag_b(N-1) := '0';

        if a(N-1) = b(N-1) then
            magnitude := mag_a + mag_b;
            sign_bit  := a(N-1);
        elsif mag_a > mag_b then
            magnitude := mag_a - mag_b;
            sign_bit  := a(N-1);
        elsif mag_b > mag_a then
            magnitude := mag_b - mag_a;
            sign_bit  := b(N-1);
        else
            magnitude := (others => '0');
            sign_bit  := '0';
        end if;

        result_v := std_logic_vector(magnitude);
        result_v(N-1) := sign_bit;
        res <= result_v;
    end process;

    c <= res;
end architecture rtl;
