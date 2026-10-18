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
    -- Sign-magnitude representation: bit N-1 is the sign.
    -- Both operands have the same Q-bit fractional scaling.
    process(a, b)
        variable magnitude_a : unsigned(N-1 downto 0);
        variable magnitude_b : unsigned(N-1 downto 0);
        variable magnitude_r : unsigned(N-1 downto 0);
        variable sign_r      : std_logic;
        variable result_v    : std_logic_vector(N-1 downto 0);
    begin
        magnitude_a := unsigned(a);
        magnitude_b := unsigned(b);
        magnitude_a(N-1) := '0';
        magnitude_b(N-1) := '0';

        magnitude_r := (others => '0');
        sign_r := '0';

        if a(N-1) = b(N-1) then
            magnitude_r := magnitude_a + magnitude_b;
            sign_r := a(N-1);
        elsif magnitude_a > magnitude_b then
            magnitude_r := magnitude_a - magnitude_b;
            sign_r := a(N-1);
        elsif magnitude_b > magnitude_a then
            magnitude_r := magnitude_b - magnitude_a;
            sign_r := b(N-1);
        else
            -- Opposite signs and equal magnitudes produce positive zero.
            magnitude_r := (others => '0');
            sign_r := '0';
        end if;

        -- Discard magnitude overflow while preserving the selected sign.
        result_v := std_logic_vector(magnitude_r);
        result_v(N-1) := sign_r;
        res <= result_v;
    end process;

    c <= res;
end architecture rtl;
