library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_subtractor is
    generic (
        Q : integer := 15;
        N : integer := 32
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end entity fixed_point_subtractor;

architecture rtl of fixed_point_subtractor is
    signal res : std_logic_vector(N-1 downto 0);
begin
    process(a, b)
        variable magnitude_a      : unsigned(N-2 downto 0);
        variable magnitude_b      : unsigned(N-2 downto 0);
        variable magnitude_result : unsigned(N-2 downto 0);
        variable sign_result      : std_logic;
    begin
        magnitude_a := unsigned(a(N-2 downto 0));
        magnitude_b := unsigned(b(N-2 downto 0));

        -- Both magnitudes have the same Q-bit fractional alignment.
        if a(N-1) = b(N-1) then
            magnitude_result := magnitude_a - magnitude_b;
            sign_result := a(N-1);
        else
            magnitude_result := magnitude_a + magnitude_b;

            if magnitude_a > magnitude_b then
                sign_result := a(N-1);
            else
                sign_result := b(N-1);
            end if;
        end if;

        -- Normalize zero to a positive sign.
        if magnitude_result = to_unsigned(0, N-1) then
            sign_result := '0';
        end if;

        res <= sign_result & std_logic_vector(magnitude_result);
    end process;

    c <= res;
end architecture rtl;
