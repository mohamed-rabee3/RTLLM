library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        a : in STD_LOGIC_VECTOR (31 downto 0);
        b : in STD_LOGIC_VECTOR (31 downto 0);
        z : out STD_LOGIC_VECTOR (31 downto 0)
    );
end float_multi;

architecture Behavioral of float_multi is
    signal counter : unsigned(2 downto 0);
    signal a_mantissa, b_mantissa, z_mantissa : unsigned(23 downto 0);
    signal a_exponent, b_exponent, z_exponent : unsigned(9 downto 0);
    signal a_sign, b_sign, z_sign : std_logic;
    signal product : unsigned(49 downto 0);
    signal guard_bit, round_bit, sticky : std_logic;
    signal z_reg : std_logic_vector(31 downto 0);
begin

    process(clk)
        variable sign_a, sign_b : std_logic;
        variable exp_a_raw, exp_b_raw : integer range 0 to 255;
        variable frac_a, frac_b : unsigned(22 downto 0);
        variable mant_a, mant_b : unsigned(23 downto 0);
        variable exp_a, exp_b : integer range -126 to 127;
        variable P : unsigned(49 downto 0);
        variable E_sum : integer range -252 to 254;
        variable L : integer range 0 to 49;
        variable E_norm : integer range -1000 to 1000;
        variable M_norm : unsigned(24 downto 0);
        variable M_sub : unsigned(24 downto 0);
        variable shift_r : natural range 0 to 200;
        variable shift_l : natural range 0 to 200;
        variable total_shift : integer range -200 to 200;
        variable guard, round_v, sticky_v : std_logic;
        variable result : std_logic_vector(31 downto 0);
        variable a_is_nan, b_is_nan : boolean;
        variable a_is_inf, b_is_inf : boolean;
        variable a_is_zero, b_is_zero : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                z_reg <= (others => '0');
                counter <= (others => '0');
            else
                result := (others => '0');
                sign_a := a(31);
                sign_b := b(31);
                exp_a_raw := to_integer(unsigned(a(30 downto 23)));
                exp_b_raw := to_integer(unsigned(b(30 downto 23)));
                frac_a := unsigned(a(22 downto 0));
                frac_b := unsigned(b(22 downto 0));

                a_is_nan := (exp_a_raw = 255) and (frac_a /= 0);
                b_is_nan := (exp_b_raw = 255) and (frac_b /= 0);
                a_is_inf := (exp_a_raw = 255) and (frac_a = 0);
                b_is_inf := (exp_b_raw = 255) and (frac_b = 0);
                a_is_zero := (exp_a_raw = 0) and (frac_a = 0);
                b_is_zero := (exp_b_raw = 0) and (frac_b = 0);

                if a_is_nan or b_is_nan then
                    result := x"7FC00000";
                elsif a_is_inf or b_is_inf then
                    if a_is_zero or b_is_zero then
                        result := x"7FC00000";
                    else
                        result(31) := sign_a xor sign_b;
                        result(30 downto 23) := (others => '1');
                        result(22 downto 0) := (others => '0');
                    end if;
                elsif a_is_zero or b_is_zero then
                    result(31) := sign_a xor sign_b;
                    result(30 downto 0) := (others => '0');
                else
                    if exp_a_raw = 0 then
                        mant_a := resize(frac_a, 24);
                        exp_a := -126;
                    else
                        mant_a := '1' & frac_a;
                        exp_a := exp_a_raw - 127;
                    end if;

                    if exp_b_raw = 0 then
                        mant_b := resize(frac_b, 24);
                        exp_b := -126;
                    else
                        mant_b := '1' & frac_b;
                        exp_b := exp_b_raw - 127;
                    end if;

                    P := resize(mant_a * mant_b, 50);

                    if P = 0 then
                        result(31) := sign_a xor sign_b;
                        result(30 downto 0) := (others => '0');
                    else
                        E_sum := exp_a + exp_b;
                        L := 0;
                        for i in 49 downto 0 loop
                            if P(i) = '1' then
                                L := i;
                                exit;
                            end if;
                        end loop;
                        E_norm := L + E_sum - 46;

                        if E_norm > 127 then
                            result(31) := sign_a xor sign_b;
                            result(30 downto 23) := (others => '1');
                            result(22 downto 0) := (others => '0');
                        elsif E_norm >= -126 then
                            if L > 23 then
                                shift_r := L - 23;
                                M_norm(23 downto 0) := resize(shift_right(P, shift_r), 24);
                                M_norm(24) := '0';
                                guard := P(shift_r-1);
                                if shift_r >= 2 then
                                    round_v := P(shift_r-2);
                                else
                                    round_v := '0';
                                end if;
                                sticky_v := '0';
                                for i in 0 to 49 loop
                                    if i < shift_r-2 then
                                        if P(i) = '1' then
                                            sticky_v := '1';
                                        end if;
                                    end if;
                                end loop;
                            else
                                shift_l := 23 - L;
                                M_norm(23 downto 0) := resize(shift_left(P, shift_l), 24);
                                M_norm(24) := '0';
                                guard := '0';
                                round_v := '0';
                                sticky_v := '0';
                            end if;

                            if (guard = '1') and (round_v = '1' or sticky_v = '1' or M_norm(0) = '1') then
                                M_norm := M_norm + 1;
                            end if;

                            if M_norm(24) = '1' then
                                M_norm := (23 => '1', others => '0');
                                E_norm := E_norm + 1;
                            end if;

                            if E_norm > 127 then
                                result(31) := sign_a xor sign_b;
                                result(30 downto 23) := (others => '1');
                                result(22 downto 0) := (others => '0');
                            else
                                result(31) := sign_a xor sign_b;
                                result(30 downto 23) := std_logic_vector(to_unsigned(E_norm + 127, 8));
                                result(22 downto 0) := std_logic_vector(M_norm(22 downto 0));
                            end if;
                        else
                            total_shift := E_sum + 103;
                            if total_shift >= 0 then
                                shift_l := total_shift;
                                M_sub(23 downto 0) := resize(shift_left(P, shift_l), 24);
                                M_sub(24) := '0';
                                guard := '0';
                                round_v := '0';
                                sticky_v := '0';
                            else
                                shift_r := -total_shift;
                                if shift_r > 50 then
                                    M_sub := (others => '0');
                                    guard := '0';
                                    round_v := '0';
                                    sticky_v := '0';
                                else
                                    M_sub(23 downto 0) := resize(shift_right(P, shift_r), 24);
                                    M_sub(24) := '0';
                                    if shift_r >= 1 then
                                        guard := P(shift_r-1);
                                    else
                                        guard := '0';
                                    end if;
                                    if shift_r >= 2 then
                                        round_v := P(shift_r-2);
                                    else
                                        round_v := '0';
                                    end if;
                                    sticky_v := '0';
                                    for i in 0 to 49 loop
                                        if i < shift_r-2 then
                                            if P(i) = '1' then
                                                sticky_v := '1';
                                            end if;
                                        end if;
                                    end loop;
                                end if;
                            end if;

                            if (guard = '1') and (round_v = '1' or sticky_v = '1' or M_sub(0) = '1') then
                                M_sub := M_sub + 1;
                            end if;

                            if M_sub(23) = '1' then
                                result(31) := sign_a xor sign_b;
                                result(30 downto 23) := std_logic_vector(to_unsigned(1, 8));
                                result(22 downto 0) := (others => '0');
                            else
                                result(31) := sign_a xor sign_b;
                                result(30 downto 23) := (others => '0');
                                result(22 downto 0) := std_logic_vector(M_sub(22 downto 0));
                            end if;
                        end if;
                    end if;
                end if;

                z_reg <= result;
                a_sign <= sign_a;
                b_sign <= sign_b;
                z_sign <= result(31);
                a_mantissa <= mant_a;
                b_mantissa <= mant_b;
                z_mantissa <= resize(unsigned(result(22 downto 0)), 24);
                a_exponent <= resize(to_unsigned(exp_a_raw, 8), 10);
                b_exponent <= resize(to_unsigned(exp_b_raw, 8), 10);
                z_exponent <= resize(to_unsigned(to_integer(unsigned(result(30 downto 23))), 8), 10);
                product <= P;
                guard_bit <= guard;
                round_bit <= round_v;
                sticky <= sticky_v;
                counter <= counter + 1;
            end if;
        end if;
    end process;

    z <= z_reg;
end Behavioral;
