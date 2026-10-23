library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fixed_point_adder is
    generic (
        Q : natural := 15;
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
    -- Inputs and output use sign-magnitude representation with Q
    -- fractional bits. No shifting or rounding is needed for addition.
    process(a, b)
        variable a_mag      : unsigned(N-1 downto 0);
        variable b_mag      : unsigned(N-1 downto 0);
        variable magnitude : unsigned(N-1 downto 0);
        variable sign_bit  : std_logic;
        variable result_v  : std_logic_vector(N-1 downto 0);
    begin
        a_mag := unsigned(a);
        b_mag := unsigned(b);
        a_mag(N-1) := '0';
        b_mag(N-1) := '0';

        if a(N-1) = b(N-1) then
            magnitude := a_mag + b_mag;
            sign_bit  := a(N-1);
        elsif a_mag > b_mag then
            magnitude := a_mag - b_mag;
            sign_bit  := a(N-1);
        elsif b_mag > a_mag then
            magnitude := b_mag - a_mag;
            sign_bit  := b(N-1);
        else
            magnitude := (others => '0');
            sign_bit  := '0';
        end if;

        -- Retain the N-1 magnitude bits, discarding magnitude overflow,
        -- and explicitly restore the sign bit.
        result_v := std_logic_vector(magnitude);
        result_v(N-1) := sign_bit;
        res <= result_v;
    end process;

    c <= res;
end architecture rtl;
