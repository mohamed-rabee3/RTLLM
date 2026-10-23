library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_divider is
    Port ( a : in STD_LOGIC_VECTOR (31 downto 0);
           b : in STD_LOGIC_VECTOR (31 downto 0);
           result : out STD_LOGIC_VECTOR (31 downto 0));
end fp_divider;

architecture Behavioral of fp_divider is
begin
    process(a, b)
        variable sign_a, sign_b : std_logic;
        variable exp_a, exp_b : unsigned(7 downto 0);
        variable frac_a, frac_b : std_logic_vector(22 downto 0);
        variable man_a, man_b : unsigned(23 downto 0);
        variable man_a_ext : unsigned(47 downto 0);
        variable Q : unsigned(47 downto 0);
        variable exp_res : unsigned(7 downto 0);
        variable frac_res : std_logic_vector(22 downto 0);
        variable sign_res : std_logic;
        variable result_var : std_logic_vector(31 downto 0);
    begin
        -- Extract fields
        sign_a := a(31);
        exp_a := unsigned(a(30 downto 23));
        frac_a := a(22 downto 0);
        sign_b := b(31);
        exp_b := unsigned(b(30 downto 23));
        frac_b := b(22 downto 0);

        -- Default
        result_var := (others => '0');

        -- Special cases
        if (exp_a = 255 and frac_a /= (others => '0')) or
           (exp_b = 255 and frac_b /= (others => '0')) or
           (exp_a = 255 and frac_a = (others => '0') and exp_b = 255 and frac_b = (others => '0')) then
            result_var := x"7FC00000";
        elsif (exp_a = 255 and frac_a = (others => '0')) then
            -- a is infinity
            result_var(31) := sign_a xor sign_b;
            result_var(30 downto 23) := (others => '1');
            result_var(22 downto 0) := (others => '0');
        elsif (exp_b = 255 and frac_b = (others => '0')) then
            -- b is infinity
            result_var(31) := sign_a xor sign_b;
            result_var(30 downto 23) := (others => '0');
            result_var(22 downto 0) := (others => '0');
        elsif (exp_b = 0 and frac_b = (others => '0')) then
            -- b is zero
            result_var(31) := sign_a xor sign_b;
            result_var(30 downto 23) := (others => '1');
            result_var(22 downto 0) := (others => '0');
        elsif (exp_a = 0 and frac_a = (others => '0')) then
            -- a is zero
            result_var := (others => '0'); -- +0
        else
            -- Normal case
            sign_res := sign_a xor sign_b;
            man_a := unsigned('1' & frac_a);
            man_b := unsigned('1' & frac_b);
            man_a_ext := shift_left(resize(man_a, 48), 24);
            Q := man_a_ext / resize(man_b, 48);
            if Q(24) = '1' then
                exp_res := exp_a - exp_b + 127;
                frac_res := std_logic_vector(Q(23 downto 1));
            else
                exp_res := exp_a - exp_b + 126;
                frac_res := std_logic_vector(Q(22 downto 0));
            end if;
            result_var(31) := sign_res;
            result_var(30 downto 23) := std_logic_vector(exp_res);
            result_var(22 downto 0) := frac_res;
        end if;

        result <= result_var;
    end process;
end Behavioral;
