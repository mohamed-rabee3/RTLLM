library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_divider is
    Port (
        a : in  STD_LOGIC_VECTOR (31 downto 0);
        b : in  STD_LOGIC_VECTOR (31 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end fp_divider;

architecture RTL of fp_divider is

    constant CANONICAL_NAN : std_logic_vector(31 downto 0) := x"7FC00000";

    signal sign_a, sign_b : std_logic;
    signal exp_a, exp_b : unsigned(7 downto 0);
    signal frac_a, frac_b : unsigned(22 downto 0);
    
    signal is_nan_a, is_nan_b : boolean;
    signal is_inf_a, is_inf_b : boolean;
    signal is_zero_a, is_zero_b : boolean;
    
    signal result_sign : std_logic;
    signal exp_base : signed(8 downto 0);
    signal exp_normal : unsigned(7 downto 0);
    signal man_a, man_b : unsigned(23 downto 0);
    signal Q : unsigned(47 downto 0);
    signal frac_normal : unsigned(22 downto 0);
    
begin

    -- Field extraction
    sign_a <= a(31);
    sign_b <= b(31);
    exp_a <= unsigned(a(30 downto 23));
    exp_b <= unsigned(b(30 downto 23));
    frac_a <= unsigned(a(22 downto 0));
    frac_b <= unsigned(b(22 downto 0));
    
    -- Special case detection
    is_nan_a <= (exp_a = 255) and (frac_a /= 0);
    is_nan_b <= (exp_b = 255) and (frac_b /= 0);
    is_inf_a <= (exp_a = 255) and (frac_a = 0);
    is_inf_b <= (exp_b = 255) and (frac_b = 0);
    is_zero_a <= (exp_a = 0) and (frac_a = 0);
    is_zero_b <= (exp_b = 0) and (frac_b = 0);
    
    -- Mantissas (implicit leading 1)
    man_a <= '1' & frac_a;
    man_b <= '1' & frac_b;
    
    -- Result sign
    result_sign <= sign_a xor sign_b;
    
    -- Mantissa division: Q = (man_a << 47) / man_b
    process(man_a, man_b)
        variable num : unsigned(70 downto 0);
        variable den : unsigned(70 downto 0);
        variable quot : unsigned(70 downto 0);
    begin
        num := man_a & (46 downto 0 => '0'); -- 24 + 47 = 71 bits
        den := resize(man_b, 71);
        quot := num / den;
        Q <= quot(47 downto 0);
    end process;
    
    -- Exponent base: exp_a - exp_b + 126
    exp_base <= signed("0" & exp_a) - signed("0" & exp_b) + 126;
    
    -- Normalization and exponent adjustment
    process(Q, exp_base)
        variable exp_var : signed(8 downto 0);
    begin
        if Q(47) = '1' then
            frac_normal <= Q(46 downto 24);
            exp_var := exp_base + 1;
        else
            frac_normal <= Q(45 downto 23);
            exp_var := exp_base;
        end if;
        exp_normal <= unsigned(exp_var(7 downto 0));
    end process;
    
    -- Output selection with priority
    process(a, b, sign_a, sign_b, is_nan_a, is_nan_b, is_inf_a, is_inf_b,
            is_zero_a, is_zero_b, result_sign, exp_normal, frac_normal)
        variable res : std_logic_vector(31 downto 0);
    begin
        if (is_nan_a or is_nan_b) or (is_inf_a and is_inf_b) then
            res := CANONICAL_NAN;
        elsif is_inf_a then
            res := result_sign & "11111111" & (22 downto 0 => '0');
        elsif is_inf_b then
            res := result_sign & "00000000" & (22 downto 0 => '0');
        elsif is_zero_b then
            res := result_sign & "11111111" & (22 downto 0 => '0');
        elsif is_zero_a then
            res := (others => '0'); -- +0
        else
            res := result_sign & std_logic_vector(exp_normal) & std_logic_vector(frac_normal);
        end if;
        result <= res;
    end process;

end RTL;
