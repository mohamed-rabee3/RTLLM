library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_subtractor is
    generic (
        Q : natural  := 15;
        N : positive := 32
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
        variable a_mag    : unsigned(N-2 downto 0);
        variable b_mag    : unsigned(N-2 downto 0);
        variable magnitude : unsigned(N-2 downto 0);
        variable result_v  : std_logic_vector(N-1 downto 0);
    begin
        a_mag := unsigned(a(N-2 downto 0));
        b_mag := unsigned(b(N-2 downto 0));
        result_v := (others => '0');

        -- Both operands have the same Q-bit fractional scaling.
        -- Magnitude arithmetic is truncated to the available N-1 bits.
        if a(N-1) = b(N-1) then
            magnitude := a_mag - b_mag;
            result_v(N-1) := a(N-1);
        else
            magnitude := a_mag + b_mag;

            if a_mag > b_mag then
                result_v(N-1) := a(N-1);
            else
                result_v(N-1) := b(N-1);
            end if;
        end if;

        result_v(N-2 downto 0) := std_logic_vector(magnitude);

        -- Canonicalize zero so that negative zero is never produced.
        if magnitude = 0 then
            result_v(N-1) := '0';
        end if;

        res <= result_v;
    end process;

    c <= res;
end architecture rtl;
