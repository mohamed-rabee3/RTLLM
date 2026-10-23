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
        variable frac_a      : unsigned(22 downto 0);
        variable frac_b      : unsigned(22 downto 0);
        variable man_a       : unsigned(23 downto 0);
        variable man_b       : unsigned(23 downto 0);
        variable exp_result  : unsigned(7 downto 0);
        variable numerator   : unsigned(47 downto 0);
        variable quotient    : unsigned(47 downto 0);
        variable fraction    : unsigned(22 downto 0);
        variable a_is_nan    : boolean;
        variable b_is_nan    : boolean;
        variable a_is_inf    : boolean;
        variable b_is_inf    : boolean;
        variable a_is_zero   : boolean;
        variable b_is_zero   : boolean;
    begin
        sign_result := a(31) xor b(31);

        exp_a  := unsigned(a(30 downto 23));
        exp_b  := unsigned(b(30 downto 23));
        frac_a := unsigned(a(22 downto 0));
        frac_b := unsigned(b(22 downto 0));

        man_a := '1' & frac_a;
        man_b := '1' & frac_b;

        a_is_nan  := (exp_a = 255) and (frac_a /= 0);
        b_is_nan  := (exp_b = 255) and (frac_b /= 0);
        a_is_inf  := (exp_a = 255) and (frac_a = 0);
        b_is_inf  := (exp_b = 255) and (frac_b = 0);
        a_is_zero := (exp_a = 0) and (frac_a = 0);
        b_is_zero := (exp_b = 0) and (frac_b = 0);

        exp_result := (others => '0');
        numerator  := (others => '0');
        quotient   := (others => '0');
        fraction   := (others => '0');

        if a_is_nan or b_is_nan or (a_is_inf and b_is_inf) then
            result <= x"7FC00000";

        elsif a_is_inf then
            result <= sign_result & "11111111" &
                      "00000000000000000000000";

        elsif b_is_inf then
            result <= sign_result & "00000000" &
                      "00000000000000000000000";

        elsif b_is_zero then
            result <= sign_result & "11111111" &
                      "00000000000000000000000";

        elsif a_is_zero then
            result <= x"00000000";

        else
            exp_result := exp_a - exp_b + to_unsigned(127, 8);
            numerator  := shift_left(resize(man_a, 48), 23);
            quotient   := numerator / man_b;

            if quotient(47) = '1' then
                fraction   := quotient(46 downto 24);
                exp_result := exp_result + to_unsigned(1, 8);
            else
                fraction := quotient(45 downto 23);
            end if;

            result <= sign_result &
                      std_logic_vector(exp_result) &
                      std_logic_vector(fraction);
        end if;
    end process;
end architecture rtl;
