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
    process (A, B)
    begin
        a_reg <= unsigned(A);
        b_reg <= unsigned(B);
    end process;

    process (a_reg, b_reg)
        variable quotient  : unsigned(15 downto 0);
        variable remainder : unsigned(16 downto 0);
        variable divisor   : unsigned(16 downto 0);
    begin
        quotient  := (others => '0');
        remainder := (others => '0');
        divisor   := resize(b_reg, divisor'length);

        -- Unrolled restoring division, processing the dividend MSB first.
        -- A zero divisor produces an all-ones quotient and remainder A.
        for i in 15 downto 0 loop
            remainder := shift_left(remainder, 1);
            remainder(0) := a_reg(i);

            if remainder >= divisor then
                remainder := remainder - divisor;
                quotient(i) := '1';
            else
                quotient(i) := '0';
            end if;
        end loop;

        result <= std_logic_vector(quotient);
        odd    <= std_logic_vector(remainder(15 downto 0));
    end process;
end architecture rtl;
