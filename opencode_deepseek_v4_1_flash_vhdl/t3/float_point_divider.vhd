library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_divider is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity fp_divider;

architecture rtl of fp_divider is
    constant EXP_FF : std_logic_vector(7 downto 0) := (others => '1');
    constant EXP_00 : std_logic_vector(7 downto 0) := (others => '0');
    constant FRAC_00 : std_logic_vector(22 downto 0) := (others => '0');

    signal sign_a, sign_b, sign_res : std_logic;
    signal exp_a, exp_b : unsigned(7 downto 0);
    signal frac_a, frac_b : unsigned(22 downto 0);
    signal man_a, man_b : unsigned(23 downto 0);
    signal is_nan_a, is_nan_b, is_inf_a, is_inf_b, is_zero_a, is_zero_b : boolean;
    signal num : unsigned(47 downto 0);
    signal q : unsigned(47 downto 0);
    signal exp_normal : unsigned(7 downto 0);
    signal exp_normal_adj : unsigned(7 downto 0);
    signal frac_normal : unsigned(22 downto 0);
begin
    -- Split operands into sign, exponent, fraction
    sign_a <= a(31);
    sign_b <= b(31);
    exp_a <= unsigned(a(30 downto 23));
    exp_b <= unsigned(b(30 downto 23));
    frac_a <= unsigned(a(22 downto 0));
    frac_b <= unsigned(b(22 downto 0));
    man_a <= '1' & frac_a;
    man_b <= '1' & frac_b;

    -- Special case flags
    is_nan_a <= (exp_a = 255) and (frac_a /= 0);
    is_nan_b <= (exp_b = 255) and (frac_b /= 0);
    is_inf_a <= (exp_a = 255) and (frac_a = 0);
    is_inf_b <= (exp_b = 255) and (frac_b = 0);
    is_zero_a <= (exp_a = 0) and (frac_a = 0);
    is_zero_b <= (exp_b = 0) and (frac_b = 0);

    -- Normal path arithmetic
    sign_res <= sign_a xor sign_b;
    exp_normal <= exp_a - exp_b + to_unsigned(127, 8);
    num <= shift_left(resize(man_a, 48), 23);
    q <= num / resize(man_b, 48);

    -- Normalize mantissa quotient
    exp_normal_adj <= exp_normal + 1 when q(47) = '1' else exp_normal;
    frac_normal <= q(46 downto 24) when q(47) = '1' else q(45 downto 23);

    -- Output selection with priority per specification
    result <= x"7FC00000" when (is_nan_a or is_nan_b or (is_inf_a and is_inf_b)) else
              sign_res & EXP_FF & FRAC_00 when is_inf_a else
              sign_res & EXP_00 & FRAC_00 when is_inf_b else
              sign_res & EXP_FF & FRAC_00 when is_zero_b else
              (others => '0') when is_zero_a else
              sign_res & std_logic_vector(exp_normal_adj) & std_logic_vector(frac_normal);

end architecture rtl;
