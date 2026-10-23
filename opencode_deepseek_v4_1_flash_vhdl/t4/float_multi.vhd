library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        a   : in STD_LOGIC_VECTOR (31 downto 0);
        b   : in STD_LOGIC_VECTOR (31 downto 0);
        z   : out STD_LOGIC_VECTOR (31 downto 0)
    );
end float_multi;

architecture Behavioral of float_multi is
    signal counter : unsigned(2 downto 0);
    signal a_mantissa, b_mantissa, z_mantissa : unsigned(23 downto 0);
    signal a_exponent, b_exponent, z_exponent : unsigned(9 downto 0);
    signal a_sign, b_sign, z_sign : std_logic;
    signal product : unsigned(49 downto 0);
    signal guard_bit, round_bit, sticky : std_logic;
begin

    process(clk, rst)
        -- Computation variables
        variable sign_a, sign_b : std_logic;
        variable exp8_a, exp8_b : unsigned(7 downto 0);
        variable frac_a, frac_b : unsigned(22 downto 0);
        variable mant_a, mant_b, mant_res : unsigned(23 downto 0);
        variable exp_a_unb, exp_b_unb : integer range -512 to 512;
        variable exp_sum : integer range -512 to 512;
        variable exp_res : integer range -512 to 512;
        variable prod : unsigned(47 downto 0);
        variable g, r, s : std_logic;
        variable is_nan_a, is_nan_b, is_inf_a, is_inf_b, is_zero_a, is_zero_b : boolean;
        variable special_nan, special_inf, special_zero : boolean;
        variable out_sign : std_logic;
        variable out_exp : unsigned(7 downto 0);
        variable out_frac : unsigned(22 downto 0);
        variable biased_exp : integer range -512 to 512;
        variable shift_s : integer range 0 to 300;
        variable round_up : boolean;
        variable sticky_sub : std_logic;
        variable round_bit_sub : std_logic;
        variable F : unsigned(23 downto 0);
        variable temp_mant : unsigned(24 downto 0);
    begin
        if rst = '1' then
            counter <= (others => '0');
            z <= (others => '0');
            a_mantissa <= (others => '0');
            b_mantissa <= (others => '0');
            z_mantissa <= (others => '0');
            a_exponent <= (others => '0');
            b_exponent <= (others => '0');
            z_exponent <= (others => '0');
            a_sign <= '0';
            b_sign <= '0';
            z_sign <= '0';
            product <= (others => '0');
            guard_bit <= '0';
            round_bit <= '0';
            sticky <= '0';
        elsif rising_edge(clk) then
            case to_integer(counter) is
                when 0 =>
                    -- Input Processing: extract sign, exponent, mantissa
                    a_sign <= a(31);
                    b_sign <= b(31);
                    a_exponent <= unsigned(a(30 downto 23));
                    b_exponent <= unsigned(b(30 downto 23));
                    a_mantissa <= unsigned(a(22 downto 0));
                    b_mantissa <= unsigned(b(22 downto 0));
                    counter <= counter + 1;

                when 1 =>
                    -- Computation and special cases handling
                    sign_a := a_sign;
                    sign_b := b_sign;
                    exp8_a := a_exponent(7 downto 0);
                    exp8_b := b_exponent(7 downto 0);
                    frac_a := a_mantissa(22 downto 0);
                    frac_b := b_mantissa(22 downto 0);

                    out_sign := sign_a xor sign_b;
                    out_exp := (others => '0');
                    out_frac := (others => '0');
                    mant_res := (others => '0');
                    special_nan := false;
                    special_inf := false;
                    special_zero := false;

                    -- Detect special cases for a
                    is_nan_a := false; is_inf_a := false; is_zero_a := false;
                    if exp8_a = 255 then
                        if frac_a /= 0 then
                            is_nan_a := true;
                        else
                            is_inf_a := true;
                        end if;
                    elsif exp8_a = 0 then
                        if frac_a = 0 then
                            is_zero_a := true;
                        end if;
                    end if;

                    -- Detect special cases for b
                    is_nan_b := false; is_inf_b := false; is_zero_b := false;
                    if exp8_b = 255 then
                        if frac_b /= 0 then
                            is_nan_b := true;
                        else
                            is_inf_b := true;
                        end if;
                    elsif exp8_b = 0 then
                        if frac_b = 0 then
                            is_zero_b := true;
                        end if;
                    end if;

                    if is_nan_a or is_nan_b then
                        special_nan := true;
                    elsif (is_inf_a and is_zero_b) or (is_inf_b and is_zero_a) then
                        special_nan := true;
                    elsif is_inf_a or is_inf_b then
                        special_inf := true;
                    elsif is_zero_a or is_zero_b then
                        special_zero := true;
                    end if;

                    if special_nan then
                        out_sign := '0';
                        out_exp := (others => '1');
                        out_frac := (others => '0');
                        out_frac(22) := '1'; -- quiet NaN
                    elsif special_inf then
                        out_exp := (others => '1');
                        out_frac := (others => '0');
                    elsif special_zero then
                        out_exp := (others => '0');
                        out_frac := (others => '0');
                    else
                        -- Normalize mantissa a
                        if exp8_a = 0 then
                            -- subnormal
                            mant_a := resize(frac_a, 24);
                            exp_a_unb := -126;
                            for i in 0 to 22 loop
                                if mant_a(23) = '0' then
                                    mant_a := mant_a(22 downto 0) & '0';
                                    exp_a_unb := exp_a_unb - 1;
                                end if;
                            end loop;
                        else
                            mant_a := resize(frac_a, 24);
                            mant_a(23) := '1';
                            exp_a_unb := to_integer(exp8_a) - 127;
                        end if;

                        -- Normalize mantissa b
                        if exp8_b = 0 then
                            mant_b := resize(frac_b, 24);
                            exp_b_unb := -126;
                            for i in 0 to 22 loop
                                if mant_b(23) = '0' then
                                    mant_b := mant_b(22 downto 0) & '0';
                                    exp_b_unb := exp_b_unb - 1;
                                end if;
                            end loop;
                        else
                            mant_b := resize(frac_b, 24);
                            mant_b(23) := '1';
                            exp_b_unb := to_integer(exp8_b) - 127;
                        end if;

                        -- Multiply mantissas
                        prod := mant_a * mant_b;
                        exp_sum := exp_a_unb + exp_b_unb;

                        -- Normalize product and extract guard/round/sticky
                        if prod(47) = '1' then
                            mant_res := prod(47 downto 24);
                            g := prod(23);
                            r := prod(22);
                            if prod(21 downto 0) = 0 then
                                s := '0';
                            else
                                s := '1';
                            end if;
                            exp_res := exp_sum + 1;
                        else
                            mant_res := prod(46 downto 23);
                            g := prod(22);
                            r := prod(21);
                            if prod(20 downto 0) = 0 then
                                s := '0';
                            else
                                s := '1';
                            end if;
                            exp_res := exp_sum;
                        end if;

                        -- Rounding and exponent adjustment
                        if exp_res >= -126 then
                            -- Normal number
                            biased_exp := exp_res + 127;
                            if biased_exp >= 255 then
                                -- Overflow to infinity
                                out_exp := (others => '1');
                                out_frac := (others => '0');
                            else
                                round_up := (g = '1') and ((r = '1') or (s = '1') or (mant_res(0) = '1'));
                                temp_mant := resize(mant_res, 25);
                                if round_up then
                                    temp_mant := temp_mant + 1;
                                end if;
                                if temp_mant(24) = '1' then
                                    mant_res := temp_mant(24 downto 1);
                                    exp_res := exp_res + 1;
                                    biased_exp := exp_res + 127;
                                else
                                    mant_res := temp_mant(23 downto 0);
                                end if;
                                if biased_exp >= 255 then
                                    out_exp := (others => '1');
                                    out_frac := (others => '0');
                                else
                                    out_exp := to_unsigned(biased_exp, 8);
                                    out_frac := mant_res(22 downto 0);
                                end if;
                            end if;
                        else
                            -- Underflow to subnormal or zero
                            shift_s := -126 - exp_res;
                            if shift_s > 24 then
                                out_exp := (others => '0');
                                out_frac := (others => '0');
                            else
                                F := (others => '0');
                                for i in 0 to 23 loop
                                    if i >= shift_s then
                                        F(i - shift_s) := mant_res(i);
                                    end if;
                                end loop;
                                round_bit_sub := '0';
                                if shift_s >= 1 then
                                    round_bit_sub := mant_res(shift_s - 1);
                                end if;
                                sticky_sub := g or r or s;
                                for i in 0 to 23 loop
                                    if i < shift_s - 1 then
                                        sticky_sub := sticky_sub or mant_res(i);
                                    end if;
                                end loop;
                                round_up := (round_bit_sub = '1') and (sticky_sub = '1' or F(0) = '1');
                                if round_up then
                                    F := F + 1;
                                end if;
                                if F(23) = '1' then
                                    -- Rounds to normal minimum
                                    out_exp := to_unsigned(1, 8);
                                    out_frac := (others => '0');
                                else
                                    out_exp := (others => '0');
                                    out_frac := F(22 downto 0);
                                end if;
                            end if;
                        end if;
                    end if;

                    -- Output Generation
                    z <= out_sign & std_logic_vector(out_exp) & std_logic_vector(out_frac);
                    z_sign <= out_sign;
                    z_exponent <= resize(out_exp, 10);
                    z_mantissa <= mant_res;
                    product <= resize(prod, 50);
                    guard_bit <= g;
                    round_bit <= r;
                    sticky <= s;
                    counter <= counter + 1;

                when 2 =>
                    counter <= counter + 1;
                when 3 =>
                    counter <= (others => '0');
                when others =>
                    counter <= (others => '0');
            end case;
        end if;
    end process;

end Behavioral;
