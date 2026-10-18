library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    port (
        clk : in std_logic;
        rst : in std_logic;
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        z : out std_logic_vector(31 downto 0)
    );
end float_multi;

architecture rtl of float_multi is
    signal counter : unsigned(2 downto 0) := (others => '0');
    signal a_mantissa, b_mantissa, z_mantissa : unsigned(23 downto 0);
    signal a_exponent, b_exponent, z_exponent : unsigned(9 downto 0);
    signal a_sign, b_sign, z_sign : std_logic;
    signal product : unsigned(49 downto 0);
    signal guard_bit, round_bit, sticky : std_logic;
begin
    process(clk, rst)
        variable sign_xor : std_logic;
        variable exp_a, exp_b : unsigned(7 downto 0);
        variable frac_a, frac_b : unsigned(22 downto 0);
        variable mant_a, mant_b : unsigned(23 downto 0);
        variable exp_a_adj, exp_b_adj : integer range 0 to 255;
        variable prod : unsigned(47 downto 0);
        variable n : integer range 0 to 47;
        variable sh : integer range -23 to 24;
        variable m_int : unsigned(23 downto 0);
        variable m_norm : unsigned(23 downto 0);
        variable e_z : integer range -1000 to 1000;
        variable biased : integer range -1000 to 1000;
        variable inc : std_logic;
        variable guard, rnd, sticky_v : std_logic;
        variable sub_shift : integer;
        variable m_sub : unsigned(23 downto 0);
        variable result : std_logic_vector(31 downto 0);
        variable is_nan, is_inf, is_zero_a, is_zero_b, is_inf_a, is_inf_b : boolean;
    begin
        if rst = '1' then
            z <= (others => '0');
            counter <= (others => '0');
        elsif rising_edge(clk) then
            sign_xor := a(31) xor b(31);
            exp_a := unsigned(a(30 downto 23));
            exp_b := unsigned(b(30 downto 23));
            frac_a := unsigned(a(22 downto 0));
            frac_b := unsigned(b(22 downto 0));
            is_zero_a := (exp_a = 0) and (frac_a = 0);
            is_zero_b := (exp_b = 0) and (frac_b = 0);
            is_inf_a := (exp_a = 255) and (frac_a = 0);
            is_inf_b := (exp_b = 255) and (frac_b = 0);
            is_nan := ((exp_a = 255) and (frac_a /= 0)) or ((exp_b = 255) and (frac_b /= 0));

            if is_nan then
                result := x"7FC00000";
            elsif (is_inf_a and is_zero_b) or (is_zero_a and is_inf_b) then
                result := x"7FC00000";
            elsif is_inf_a or is_inf_b then
                result := sign_xor & "11111111" & "00000000000000000000000";
            elsif is_zero_a or is_zero_b then
                result := sign_xor & "00000000" & "00000000000000000000000";
            else
                if exp_a = 0 then
                    mant_a := '0' & frac_a;
                    exp_a_adj := 1;
                else
                    mant_a := '1' & frac_a;
                    exp_a_adj := to_integer(exp_a);
                end if;
                if exp_b = 0 then
                    mant_b := '0' & frac_b;
                    exp_b_adj := 1;
                else
                    mant_b := '1' & frac_b;
                    exp_b_adj := to_integer(exp_b);
                end if;

                prod := mant_a * mant_b;

                n := 0;
                for i in 47 downto 0 loop
                    if prod(i) = '1' then
                        n := i;
                        exit;
                    end if;
                end loop;

                sh := n - 23;
                if sh >= 0 then
                    if sh = 0 then
                        m_int := prod(23 downto 0);
                        guard := '0'; rnd := '0'; sticky_v := '0';
                    else
                        m_int := resize(shift_right(prod, sh), 24);
                        guard := prod(sh - 1);
                        if sh > 1 then
                            rnd := prod(sh - 2);
                        else
                            rnd := '0';
                        end if;
                        sticky_v := '0';
                        for i in 0 to 47 loop
                            if i < sh - 2 then
                                sticky_v := sticky_v or prod(i);
                            end if;
                        end loop;
                    end if;
                    inc := '0';
                    if guard = '1' and (rnd = '1' or sticky_v = '1' or m_int(0) = '1') then
                        inc := '1';
                    end if;
                    if inc = '1' then
                        if m_int = x"FFFFFF" then
                            m_norm := x"800000";
                            e_z := (exp_a_adj + exp_b_adj - 254) + n - 46 + 1;
                        else
                            m_norm := m_int + 1;
                            e_z := (exp_a_adj + exp_b_adj - 254) + n - 46;
                        end if;
                    else
                        m_norm := m_int;
                        e_z := (exp_a_adj + exp_b_adj - 254) + n - 46;
                    end if;
                else
                    m_int := resize(shift_left(prod, -sh), 24);
                    m_norm := m_int;
                    e_z := (exp_a_adj + exp_b_adj - 254) + n - 46;
                end if;

                biased := e_z + 127;
                if biased >= 255 then
                    result := sign_xor & "11111111" & "00000000000000000000000";
                elsif biased <= 0 then
                    sub_shift := -126 - e_z;
                    if sub_shift <= 0 then
                        result := sign_xor & "00000001" & std_logic_vector(m_norm(22 downto 0));
                    elsif sub_shift >= 24 then
                        if sub_shift = 24 then
                            guard := m_norm(23);
                            rnd := m_norm(22);
                            sticky_v := '0';
                            for i in 0 to 23 loop
                                if i < 22 then
                                    sticky_v := sticky_v or m_norm(i);
                                end if;
                            end loop;
                            if guard = '1' and (rnd = '1' or sticky_v = '1') then
                                m_sub := (0 => '1', others => '0');
                            else
                                m_sub := (others => '0');
                            end if;
                        else
                            m_sub := (others => '0');
                        end if;
                    else
                        m_sub := resize(shift_right(m_norm, sub_shift), 24);
                        guard := m_norm(sub_shift - 1);
                        if sub_shift > 1 then
                            rnd := m_norm(sub_shift - 2);
                        else
                            rnd := '0';
                        end if;
                        sticky_v := '0';
                        for i in 0 to 23 loop
                            if i < sub_shift - 2 then
                                sticky_v := sticky_v or m_norm(i);
                            end if;
                        end loop;
                        inc := '0';
                        if guard = '1' and (rnd = '1' or sticky_v = '1' or m_sub(0) = '1') then
                            inc := '1';
                        end if;
                        if inc = '1' then
                            m_sub := m_sub + 1;
                        end if;
                    end if;
                    if m_sub >= x"800000" then
                        result := sign_xor & "00000001" & "00000000000000000000000";
                    else
                        result := sign_xor & "00000000" & std_logic_vector(m_sub(22 downto 0));
                    end if;
                else
                    result := sign_xor & std_logic_vector(to_unsigned(biased, 8)) & std_logic_vector(m_norm(22 downto 0));
                end if;
            end if;
            z <= result;
            counter <= counter + 1;
        end if;
    end process;
end rtl;
