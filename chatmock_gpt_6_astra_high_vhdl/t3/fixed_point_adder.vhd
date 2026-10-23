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
    process(a, b)
        variable mag_a   : unsigned(N-1 downto 0);
        variable mag_b   : unsigned(N-1 downto 0);
        variable mag_res : unsigned(N-1 downto 0);
        variable result : std_logic_vector(N-1 downto 0);
        variable sign_r : std_logic;
    begin
        -- Sign-magnitude operands share the same binary-point position.
        mag_a := unsigned(a);
        mag_b := unsigned(b);
        mag_a(N-1) := '0';
        mag_b(N-1) := '0';

        mag_res := (others => '0');
        sign_r  := '0';

        if a(N-1) = b(N-1) then
            mag_res := mag_a + mag_b;
            sign_r  := a(N-1);
        elsif mag_a > mag_b then
            mag_res := mag_a - mag_b;
            sign_r  := a(N-1);
        elsif mag_b > mag_a then
            mag_res := mag_b - mag_a;
            sign_r  := b(N-1);
        else
            -- Opposite signs with equal magnitudes produce positive zero.
            mag_res := (others => '0');
            sign_r  := '0';
        end if;

        -- Discard any magnitude overflow and preserve the selected sign.
        result := std_logic_vector(mag_res);
        result(N-1) := sign_r;
        res <= result;
    end process;

    c <= res;
end architecture rtl;
