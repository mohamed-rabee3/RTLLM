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
        variable a_magnitude      : unsigned(N-2 downto 0);
        variable b_magnitude      : unsigned(N-2 downto 0);
        variable result_magnitude : unsigned(N-2 downto 0);
        variable result_sign      : std_logic;
    begin
        a_magnitude := unsigned(a(N-2 downto 0));
        b_magnitude := unsigned(b(N-2 downto 0));

        -- Both operands share Q fractional bits, so no scaling is needed.
        if a(N-1) = b(N-1) then
            result_magnitude := a_magnitude - b_magnitude;
            result_sign := a(N-1);
        else
            result_magnitude := a_magnitude + b_magnitude;

            if a_magnitude > b_magnitude then
                result_sign := a(N-1);
            else
                result_sign := b(N-1);
            end if;
        end if;

        -- Canonicalize zero to a positive sign.
        if result_magnitude = to_unsigned(0, N-1) then
            result_sign := '0';
        end if;

        res <= result_sign & std_logic_vector(result_magnitude);
    end process;

    c <= res;
end architecture rtl;
