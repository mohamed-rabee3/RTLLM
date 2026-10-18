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
        variable frac_a      : unsigned(22 downto 0);
        variable frac_b      : unsigned(22 downto 0);
        variable man_a       : unsigned(23 downto 0);
        variable man_b       : unsigned(23 downto 0);
        variable numerator   : unsigned(47 downto 0);
        variable quotient    : unsigned(47 downto 0);
        variable result_v    : std_logic_vector(31 downto 0);
        variable a_nan       : boolean;
        variable b_nan       : boolean;
        variable a_inf       : boolean;
        variable b_inf       : boolean;
        variable a_zero      : boolean;
        variable b_zero      : boolean;
    begin
        sign_result := a(31) xor b(31);
        exp_a       := unsigned(a(30 downto 23));
        exp_b       := unsigned(b(30 downto 23));
        frac_a      := unsigned(a(22 downto 0));
        frac_b      := unsigned(b(22 downto 0));

        man_a := '1' & frac_a;
        man_b := '1' & frac_b;

        a_nan  := (exp_a = 255) and (frac_a /= 0);
        b_nan  := (exp_b = 255) and (frac_b /= 0);
        a_inf  := (exp_a = 255) and (frac_a = 0);
        b_inf  := (exp_b = 255) and (frac_b = 0);
        a_zero := (exp_a = 0) and (frac_a = 0);
        b_zero := (exp_b = 0) and (frac_b = 0);

        result_v   := (others => '0');
        exp_result := (others => '0');
        numerator  := (others => '0');
        quotient   := (others => '0');

        if a_nan or b_nan or (a_inf and b_inf) then
            result_v := x"7FC00000";

        elsif a_inf then
            result_v(31)           := sign_result;
            result_v(30 downto 23) := (others => '1');

        elsif b_inf then
            result_v(31) := sign_result;

        elsif b_zero then
            result_v(31)           := sign_result;
            result_v(30 downto 23) := (others => '1');

        elsif a_zero then
            result_v := (others => '0');

        else
            exp_result := exp_a - exp_b + to_unsigned(127, 8);
            numerator  := shift_left(resize(man_a, 48), 23);
            quotient   := numerator / resize(man_b, 48);

            if quotient(47) = '1' then
                result_v(22 downto 0) :=
                    std_logic_vector(quotient(46 downto 24));
                exp_result := exp_result + to_unsigned(1, 8);
            else
                result_v(22 downto 0) :=
                    std_logic_vector(quotient(45 downto 23));
            end if;

            result_v(31)           := sign_result;
            result_v(30 downto 23) := std_logic_vector(exp_result);
        end if;

        result <= result_v;
    end process;
end architecture rtl;
