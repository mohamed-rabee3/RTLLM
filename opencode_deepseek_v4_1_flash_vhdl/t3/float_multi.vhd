library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    Port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic_vector(31 downto 0);
        b   : in  std_logic_vector(31 downto 0);
        z   : out std_logic_vector(31 downto 0)
    );
end float_multi;

architecture rtl of float_multi is
    signal counter : std_logic_vector(2 downto 0);
    signal a_mantissa, b_mantissa, z_mantissa : unsigned(23 downto 0);
    signal a_exponent, b_exponent, z_exponent : std_logic_vector(9 downto 0);
    signal a_sign, b_sign, z_sign : std_logic;
    signal product : unsigned(49 downto 0);
    signal guard_bit, round_bit, sticky : std_logic;
    signal a_reg, b_reg : std_logic_vector(31 downto 0);

    function fp_mul_func(a, b : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable sign_z : std_logic;
        variable exp_a, exp_b : unsigned(7 downto 0);
        variable frac_a, frac_b : unsigned(22 downto 0);
        variable man_a, man_b : unsigned(23 downto 0);
        variable e_a, e_b : integer range 0 to 255;
        variable product : unsigned(47 downto 0);
        variable L : integer range 0 to 47;
        variable shift : integer range -23 to 24;
        variable E_field : integer range -200 to 600;
        variable Q : unsigned(23 downto 0);
        variable Q_round : unsigned(24 downto 0);
        variable M : unsigned(23 downto 0);
        variable guard, sticky : std_logic;
        variable result : std_logic_vector(31 downto 0);
        variable temp : unsigned(47 downto 0);
        variable total_shift : integer range -100 to 200;
    begin
        result := (others => '0');
        sign_z := a(31) xor b(31);
        exp_a := unsigned(a(30 downto 23));
        exp_b := unsigned(b(30 downto 23));
        frac_a := unsigned(a(22 downto 0));
        frac_b := unsigned(b(22 downto 0));

        -- NaN check
        if (exp_a = 255 and frac_a /= 0) or (exp_b = 255 and frac_b /= 0) then
            result(31) := '0';
            result(30 downto 23) := x"FF";
            result(22 downto 0) := "10000000000000000000000";
            return result;
        end if;

        -- Infinity
        if (exp_a = 255 and frac_a = 0) or (exp_b = 255 and frac_b = 0) then
            if (exp_a = 255 and frac_a = 0) and (exp_b = 0 and frac_b = 0) then
                result(31) := '0';
                result(30 downto 23) := x"FF";
                result(22 downto 0) := "10000000000000000000000";
                return result;
            elsif (exp_b = 255 and frac_b = 0) and (exp_a = 0 and frac_a = 0) then
                result(31) := '0';
                result(30 downto 23) := x"FF";
                result(22 downto 0) := "10000000000000000000000";
                return result;
            else
                result(31) := sign_z;
                result(30 downto 23) := x"FF";
                result(22 downto 0) := (others => '0');
                return result;
            end if;
        end if;

        -- Zero
        if (exp_a = 0 and frac_a = 0) or (exp_b = 0 and frac_b = 0) then
            result(31) := sign_z;
            result(30 downto 23) := x"00";
            result(22 downto 0) := (others => '0');
            return result;
        end if;

        -- significands
        if exp_a = 0 then
            man_a := '0' & frac_a;
            e_a := 1;
        else
            man_a := '1' & frac_a;
            e_a := to_integer(exp_a);
        end if;
        if exp_b = 0 then
            man_b := '0' & frac_b;
            e_b := 1;
        else
            man_b := '1' & frac_b;
            e_b := to_integer(exp_b);
        end if;

        product := man_a * man_b;
        if product = 0 then
            result(31) := sign_z;
            result(30 downto 23) := x"00";
            result(22 downto 0) := (others => '0');
            return result;
        end if;

        L := 0;
        for i in 47 downto 0 loop
            if product(i) = '1' then
                L := i;
                exit;
            end if;
        end loop;

        shift := L - 23;
        E_field := e_a + e_b + shift - 150;

        if E_field >= 1 then
            -- Normal result
            if shift >= 0 then
                temp := shift_right(product, shift);
                Q := temp(23 downto 0);
                if shift > 0 then
                    guard := product(shift-1);
                    sticky := '0';
                    for i in 0 to 47 loop
                        if i < shift-1 then
                            sticky := sticky or product(i);
                        end if;
                    end loop;
                else
                    guard := '0';
                    sticky := '0';
                end if;
            else
                temp := shift_left(product, -shift);
                Q := resize(temp, 24);
                guard := '0';
                sticky := '0';
            end if;

            Q_round := resize(Q, 25);
            if guard = '1' and (sticky = '1' or Q(0) = '1') then
                Q_round := Q_round + 1;
            end if;

            if Q_round(24) = '1' then
                E_field := E_field + 1;
                Q := (others => '0');
            else
                Q := Q_round(23 downto 0);
            end if;

            if E_field >= 255 then
                result(31) := sign_z;
                result(30 downto 23) := x"FF";
                result(22 downto 0) := (others => '0');
                return result;
            elsif E_field <= 0 then
                result(31) := sign_z;
                result(30 downto 23) := x"00";
                result(22 downto 0) := (others => '0');
                return result;
            else
                result(31) := sign_z;
                result(30 downto 23) := std_logic_vector(to_unsigned(E_field, 8));
                result(22 downto 0) := std_logic_vector(Q(22 downto 0));
                return result;
            end if;
        else
            -- Subnormal result
            total_shift := 151 - e_a - e_b;
            if total_shift > 48 then
                M := (others => '0');
                guard := '0';
                sticky := '0';
            elsif total_shift = 48 then
                M := (others => '0');
                guard := product(47);
                sticky := '0';
                for i in 0 to 46 loop
                    sticky := sticky or product(i);
                end loop;
            elsif total_shift > 0 then
                temp := shift_right(product, total_shift);
                M := resize(temp, 24);
                guard := product(total_shift-1);
                sticky := '0';
                for i in 0 to 47 loop
                    if i < total_shift-1 then
                        sticky := sticky or product(i);
                    end if;
                end loop;
            else
                temp := shift_left(product, -total_shift);
                M := resize(temp, 24);
                guard := '0';
                sticky := '0';
            end if;

            if guard = '1' and (sticky = '1' or M(0) = '1') then
                M := M + 1;
            end if;

            if M(23) = '1' then
                result(31) := sign_z;
                result(30 downto 23) := x"01";
                result(22 downto 0) := (others => '0');
                return result;
            else
                result(31) := sign_z;
                result(30 downto 23) := x"00";
                result(22 downto 0) := std_logic_vector(M(22 downto 0));
                return result;
            end if;
        end if;
    end function;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter <= "000";
                z <= (others => '0');
                a_reg <= (others => '0');
                b_reg <= (others => '0');
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
            else
                case counter is
                    when "000" =>
                        a_reg <= a;
                        b_reg <= b;
                        a_sign <= a(31);
                        b_sign <= b(31);
                        a_exponent <= "00" & a(30 downto 23);
                        b_exponent <= "00" & b(30 downto 23);
                        if a(30 downto 23) = x"00" then
                            a_mantissa <= '0' & unsigned(a(22 downto 0));
                        else
                            a_mantissa <= '1' & unsigned(a(22 downto 0));
                        end if;
                        if b(30 downto 23) = x"00" then
                            b_mantissa <= '0' & unsigned(b(22 downto 0));
                        else
                            b_mantissa <= '1' & unsigned(b(22 downto 0));
                        end if;
                        counter <= "001";
                    when "001" =>
                        z <= fp_mul_func(a_reg, b_reg);
                        z_sign <= a_sign xor b_sign;
                        product <= resize(a_mantissa * b_mantissa, 50);
                        counter <= "010";
                    when others =>
                        counter <= "000";
                end case;
            end if;
        end if;
    end process;
end rtl;
