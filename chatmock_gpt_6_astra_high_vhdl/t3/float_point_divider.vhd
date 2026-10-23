library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_divider is
    port (
        a      : in  std_logic_vector(31 downto 0);
        b      : in  std_logic_vector(31 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity fp_divider;

architecture rtl of fp_divider is
begin
    process(a, b)
        variable sign_result : std_logic;
        variable exp_a       : unsigned(7 downto 0);
        variable exp_b       : unsigned(7 downto 0);
        variable exp_result  : unsigned(7 downto 0);
        variable frac_a      : std_logic_vector(22 downto 0);
        variable frac_b      : std_logic_vector(22 downto 0);
        variable frac_result : std_logic_vector(22 downto 0);
        variable man_a       : unsigned(23 downto 0);
        variable man_b       : unsigned(23 downto 0);
        variable numerator   : unsigned(47 downto 0);
        variable quotient    : unsigned(47 downto 0);
        variable a_nan       : boolean;
        variable b_nan       : boolean;
        variable a_inf       : boolean;
        variable b_inf       : boolean;
        variable a_zero      : boolean;
        variable b_zero      : boolean;

        constant ZERO_FRAC : std_logic_vector(22 downto 0) :=
            (others => '0');
    begin
        sign_result := a(31) xor b(31);
        exp_a       := unsigned(a(30 downto 23));
        exp_b       := unsigned(b(30 downto 23));
        frac_a      := a(22 downto 0);
        frac_b      := b(22 downto 0);
        man_a       := unsigned('1' & frac_a);
        man_b       := unsigned('1' & frac_b);

        a_nan  := (exp_a = to_unsigned(255, 8)) and
                  (frac_a /= ZERO_FRAC);
        b_nan  := (exp_b = to_unsigned(255, 8)) and
                  (frac_b /= ZERO_FRAC);
        a_inf  := (exp_a = to_unsigned(255, 8)) and
                  (frac_a = ZERO_FRAC);
        b_inf  := (exp_b = to_unsigned(255, 8)) and
                  (frac_b = ZERO_FRAC);
        a_zero := (exp_a = to_unsigned(0, 8)) and
                  (frac_a = ZERO_FRAC);
        b_zero := (exp_b = to_unsigned(0, 8)) and
                  (frac_b = ZERO_FRAC);

        exp_result  := (others => '0');
        frac_result := (others => '0');
        numerator   := (others => '0');
        quotient    := (others => '0');

        if a_nan or b_nan or (a_inf and b_inf) then
            result <= x"7FC00000";
        elsif a_inf then
            result <= sign_result & x"FF" & ZERO_FRAC;
        elsif b_inf then
            result <= sign_result & x"00" & ZERO_FRAC;
        elsif b_zero then
            result <= sign_result & x"FF" & ZERO_FRAC;
        elsif a_zero then
            result <= x"00000000";
        else
            exp_result := exp_a - exp_b + to_unsigned(127, 8);
            numerator  := shift_left(resize(man_a, 48), 23);
            quotient   := numerator / resize(man_b, 48);

            if quotient(47) = '1' then
                frac_result := std_logic_vector(quotient(46 downto 24));
                exp_result  := exp_result + to_unsigned(1, 8);
            else
                frac_result := std_logic_vector(quotient(45 downto 23));
            end if;

            result <= sign_result & std_logic_vector(exp_result) &
                      frac_result;
        end if;
    end process;
end architecture rtl;
