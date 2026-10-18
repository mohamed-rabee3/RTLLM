library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_divider is
    Port ( a : in  STD_LOGIC_VECTOR (31 downto 0);
           b : in  STD_LOGIC_VECTOR (31 downto 0);
           result : out  STD_LOGIC_VECTOR (31 downto 0));
end fp_divider;

architecture Behavioral of fp_divider is
begin
    process(a, b)
        variable sign_a, sign_b : std_logic;
        variable exp_a, exp_b : unsigned(7 downto 0);
        variable frac_a, frac_b : unsigned(22 downto 0);
        variable man_a, man_b : unsigned(23 downto 0);
        variable is_nan_a, is_nan_b : boolean;
        variable is_inf_a, is_inf_b : boolean;
        variable is_zero_a, is_zero_b : boolean;
        variable v_sign : std_logic;
        variable v_exp : unsigned(7 downto 0);
        variable v_frac : unsigned(22 downto 0);
        variable numerator : unsigned(47 downto 0);
        variable denominator : unsigned(47 downto 0);
        variable quotient : unsigned(47 downto 0);
    begin
        -- Split inputs
        sign_a := a(31);
        exp_a := unsigned(a(30 downto 23));
        frac_a := unsigned(a(22 downto 0));
        sign_b := b(31);
        exp_b := unsigned(b(30 downto 23));
        frac_b := unsigned(b(22 downto 0));

        -- Special cases detection
        is_nan_a := (exp_a = 255) and (frac_a /= 0);
        is_nan_b := (exp_b = 255) and (frac_b /= 0);
        is_inf_a := (exp_a = 255) and (frac_a = 0);
        is_inf_b := (exp_b = 255) and (frac_b = 0);
        is_zero_a := (exp_a = 0) and (frac_a = 0);
        is_zero_b := (exp_b = 0) and (frac_b = 0);

        -- Mantissa formation
        man_a := '1' & frac_a;
        man_b := '1' & frac_b;

        v_sign := sign_a xor sign_b;

        if is_nan_a or is_nan_b or (is_inf_a and is_inf_b) then
            result <= x"7FC00000";
        elsif is_inf_a then
            result <= v_sign & x"FF" & (22 downto 0 => '0');
        elsif is_inf_b then
            result <= v_sign & x"00" & (22 downto 0 => '0');
        elsif is_zero_b then
            result <= v_sign & x"FF" & (22 downto 0 => '0');
        elsif is_zero_a then
            result <= x"00000000";
        else
            -- Normal case
            numerator := man_a & to_unsigned(0, 24);
            denominator := resize(man_b, 48);
            quotient := numerator / denominator;

            if quotient(24) = '1' then
                v_frac := quotient(23 downto 1);
                v_exp := exp_a - exp_b + to_unsigned(127, 8);
            else
                v_frac := quotient(22 downto 0);
                v_exp := exp_a - exp_b + to_unsigned(126, 8);
            end if;

            result <= v_sign & std_logic_vector(v_exp) & std_logic_vector(v_frac);
        end if;
    end process;
end Behavioral;
