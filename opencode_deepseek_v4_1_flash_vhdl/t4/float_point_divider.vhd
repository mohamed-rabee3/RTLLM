library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_divider is
    Port (
        a      : in  STD_LOGIC_VECTOR(31 downto 0);
        b      : in  STD_LOGIC_VECTOR(31 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0)
    );
end fp_divider;

architecture Behavioral of fp_divider is
    constant ZERO23 : std_logic_vector(22 downto 0) := (others => '0');
    signal sign_a, sign_b : std_logic;
    signal exp_a, exp_b   : std_logic_vector(7 downto 0);
    signal frac_a, frac_b : std_logic_vector(22 downto 0);
    
    signal a_nan, b_nan, a_inf, b_inf, a_zero, b_zero : boolean;
    
    signal ma, mb : unsigned(23 downto 0);
    signal numerator : unsigned(47 downto 0);
    signal quotient : unsigned(47 downto 0);
    signal q24 : unsigned(23 downto 0);
    signal exp_result : std_logic_vector(7 downto 0);
    signal frac_result : std_logic_vector(22 downto 0);
    signal sign_result : std_logic;
begin
    sign_a <= a(31);
    sign_b <= b(31);
    exp_a  <= a(30 downto 23);
    exp_b  <= b(30 downto 23);
    frac_a <= a(22 downto 0);
    frac_b <= b(22 downto 0);
    
    a_nan <= (exp_a = x"FF") and (frac_a /= ZERO23);
    b_nan <= (exp_b = x"FF") and (frac_b /= ZERO23);
    a_inf <= (exp_a = x"FF") and (frac_a = ZERO23);
    b_inf <= (exp_b = x"FF") and (frac_b = ZERO23);
    a_zero <= (exp_a = x"00") and (frac_a = ZERO23);
    b_zero <= (exp_b = x"00") and (frac_b = ZERO23);
    
    ma <= unsigned('1' & frac_a);
    mb <= unsigned('1' & frac_b);
    
    numerator <= shift_left(resize(ma, 48), 23);
    quotient <= numerator / mb;
    q24 <= quotient(23 downto 0);
    
    exp_result <= std_logic_vector(unsigned(exp_a) - unsigned(exp_b) + 127) when q24(23) = '1' else
                  std_logic_vector(unsigned(exp_a) - unsigned(exp_b) + 126);
    
    frac_result <= std_logic_vector(q24(22 downto 0)) when q24(23) = '1' else
                   std_logic_vector(q24(21 downto 0)) & '0';
    
    sign_result <= sign_a xor sign_b;
    
    result <= x"7FC00000" when (a_nan or b_nan or (a_inf and b_inf)) else
              sign_a & x"FF" & ZERO23 when a_inf else
              sign_result & x"00" & ZERO23 when b_inf else
              sign_result & x"FF" & ZERO23 when b_zero else
              x"00000000" when a_zero else
              sign_result & exp_result & frac_result;
              
end Behavioral;
