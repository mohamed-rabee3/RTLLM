library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_fp_divider is
    port(a      : in  std_logic_vector(31 downto 0);
         b      : in  std_logic_vector(31 downto 0);
         result : out std_logic_vector(31 downto 0));
end verified_fp_divider;
architecture rtl of verified_fp_divider is
begin
    process(a, b)
        variable sign_a, sign_b, sign_r : std_logic;
        variable exp_a, exp_b, exp_r     : unsigned(7 downto 0);
        variable man_a, man_b            : unsigned(23 downto 0);
        variable man_div                 : unsigned(47 downto 0);
        variable mantissa                : std_logic_vector(22 downto 0);
        variable a_zero, b_zero, a_inf, b_inf, a_nan, b_nan : boolean;
    begin
        sign_a := a(31);
        sign_b := b(31);
        exp_a  := unsigned(a(30 downto 23));
        exp_b  := unsigned(b(30 downto 23));
        man_a  := unsigned('1' & a(22 downto 0));
        man_b  := unsigned('1' & b(22 downto 0));

        a_zero := (exp_a = 0   and unsigned(a(22 downto 0)) = 0);
        b_zero := (exp_b = 0   and unsigned(b(22 downto 0)) = 0);
        a_inf  := (exp_a = 255 and unsigned(a(22 downto 0)) = 0);
        b_inf  := (exp_b = 255 and unsigned(b(22 downto 0)) = 0);
        a_nan  := (exp_a = 255 and unsigned(a(22 downto 0)) /= 0);
        b_nan  := (exp_b = 255 and unsigned(b(22 downto 0)) /= 0);

        if a_nan or b_nan then
            result <= x"7FC00000";
        elsif a_inf and b_inf then
            result <= x"7FC00000";
        elsif a_inf then
            result <= (sign_a xor sign_b) & x"FF" & (22 downto 0 => '0');
        elsif b_inf then
            result <= (sign_a xor sign_b) & x"00" & (22 downto 0 => '0');
        elsif b_zero then
            result <= (sign_a xor sign_b) & x"FF" & (22 downto 0 => '0');
        elsif a_zero then
            result <= x"00000000";
        else
            sign_r  := sign_a xor sign_b;
            exp_r   := exp_a - exp_b + 127;
            man_div := shift_left(resize(man_a, 48), 23) / resize(man_b, 48);
            if man_div(47) = '1' then
                mantissa := std_logic_vector(man_div(46 downto 24));
                exp_r    := exp_r + 1;
            else
                mantissa := std_logic_vector(man_div(45 downto 23));
            end if;
            result <= sign_r & std_logic_vector(exp_r) & mantissa;
        end if;
    end process;
end rtl;
