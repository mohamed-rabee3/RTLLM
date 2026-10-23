library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity div_16bit is
    port (
        A      : in  std_logic_vector(15 downto 0);
        B      : in  std_logic_vector(7 downto 0);
        result : out std_logic_vector(15 downto 0);
        odd    : out std_logic_vector(15 downto 0)
    );
end entity div_16bit;

architecture rtl of div_16bit is
    signal a_reg : unsigned(15 downto 0);
    signal b_reg : unsigned(7 downto 0);
begin
    input_comb : process(A, B)
    begin
        a_reg <= unsigned(A);
        b_reg <= unsigned(B);
    end process input_comb;

    divide_comb : process(a_reg, b_reg)
        variable quotient_v  : unsigned(15 downto 0);
        variable remainder_v : unsigned(16 downto 0);
        variable divisor_v   : unsigned(16 downto 0);
    begin
        quotient_v  := (others => '0');
        remainder_v := (others => '0');
        divisor_v   := resize(b_reg, divisor_v'length);

        -- Unrolled restoring division, processing the dividend MSB first.
        -- For B = 0, this produces result = x"FFFF" and odd = A.
        for i in 15 downto 0 loop
            remainder_v := remainder_v(15 downto 0) & a_reg(i);

            if remainder_v >= divisor_v then
                remainder_v := remainder_v - divisor_v;
                quotient_v(i) := '1';
            else
                quotient_v(i) := '0';
            end if;
        end loop;

        result <= std_logic_vector(quotient_v);
        odd    <= std_logic_vector(remainder_v(15 downto 0));
    end process divide_comb;
end architecture rtl;
