library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    Port (
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        a   : in  STD_LOGIC_VECTOR(31 downto 0);
        b   : in  STD_LOGIC_VECTOR(31 downto 0);
        z   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end float_multi;

architecture Behavioral of float_multi is

    -- Pre-defined internal signals (as per specification)
    signal counter      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal a_mantissa   : STD_LOGIC_VECTOR(23 downto 0);
    signal b_mantissa   : STD_LOGIC_VECTOR(23 downto 0);
    signal z_mantissa   : STD_LOGIC_VECTOR(23 downto 0);
    signal a_exponent   : STD_LOGIC_VECTOR(9 downto 0);
    signal b_exponent   : STD_LOGIC_VECTOR(9 downto 0);
    signal z_exponent   : STD_LOGIC_VECTOR(9 downto 0);
    signal a_sign       : STD_LOGIC;
    signal b_sign       : STD_LOGIC;
    signal z_sign       : STD_LOGIC;
    signal product      : STD_LOGIC_VECTOR(49 downto 0);
    signal guard_bit    : STD_LOGIC;
    signal round_bit    : STD_LOGIC;
    signal sticky       : STD_LOGIC;

    -- Additional internal registers
    signal a_is_nan     : STD_LOGIC;
    signal a_is_inf     : STD_LOGIC;
    signal a_is_zero    : STD_LOGIC;
    signal a_is_denorm  : STD_LOGIC;
    signal b_is_nan     : STD_LOGIC;
    signal b_is_inf     : STD_LOGIC;
    signal b_is_zero    : STD_LOGIC;
    signal b_is_denorm  : STD_LOGIC;

    signal a_norm_mant  : STD_LOGIC_VECTOR(23 downto 0);
    signal b_norm_mant  : STD_LOGIC_VECTOR(23 downto 0);
    signal a_unb_exp    : STD_LOGIC_VECTOR(9 downto 0);
    signal b_unb_exp    : STD_LOGIC_VECTOR(9 downto 0);
    signal exp_sum_unb  : STD_LOGIC_VECTOR(9 downto 0);

    -- Function to count leading zeros in a 24-bit vector
    function count_leading_zeros_24(slv : STD_LOGIC_VECTOR(23 downto 0)) return unsigned is
        variable cnt : unsigned(4 downto 0) := (others => '0');
    begin
        for i in 23 downto 0 loop
            if slv(i) = '1' then
                return cnt;
            else
                cnt := cnt + 1;
            end if;
        end loop;
        return cnt; -- 24 if all zeros (should not happen for denormal)
    end function;

begin

    -- Main synchronous process
    process(clk, rst)
        -- Variables for temporary calculations
        variable lzc_a        : unsigned(4 downto 0);
        variable lzc_b        : unsigned(4 downto 0);
        variable in24_a       : STD_LOGIC_VECTOR(23 downto 0);
        variable in24_b       : STD_LOGIC_VECTOR(23 downto 0);
        variable mant_post_25 : STD_LOGIC_VECTOR(24 downto 0);
        variable biased_exp   : integer;
        variable round_up     : boolean;
    begin
        if rst = '1' then
            -- Reset all registers to default values
            counter       <= (others => '0');
            a_sign        <= '0';
            b_sign        <= '0';
            z_sign        <= '0';
            a_exponent    <= (others => '0');
            b_exponent    <= (others => '0');
            z_exponent    <= (others => '0');
            a_mantissa    <= (others => '0');
            b_mantissa    <= (others => '0');
            z_mantissa    <= (others => '0');
            product       <= (others => '0');
            guard_bit     <= '0';
            round_bit     <= '0';
            sticky        <= '0';
            a_is_nan      <= '0';
            a_is_inf      <= '0';
            a_is_zero     <= '0';
            a_is_denorm   <= '0';
            b_is_nan      <= '0';
            b_is_inf      <= '0';
            b_is_zero     <= '0';
            b_is_denorm   <= '0';
            a_norm_mant   <= (others => '0');
            b_norm_mant   <= (others => '0');
            a_unb_exp     <= (others => '0');
            b_unb_exp     <= (others => '0');
            exp_sum_unb   <= (others => '0');
            z             <= (others => '0');

        elsif rising_edge(clk) then
            -- Sequential state machine
            case counter is

                -- State 0: Latch inputs and detect special cases
                when "000" =>
                    a_sign      <= a(31);
                    a_exponent  <= "00" & a(30 downto 23);
                    a_mantissa  <= a(22 downto 0);
                    b_sign      <= b(31);
                    b_exponent  <= "00" & b(30 downto 23);
                    b_mantissa  <= b(22 downto 0);

                    -- Detect special cases for operand a
                    if a(30 downto 23) = "11111111" then
                        if a(22 downto 0) = "00000000000000000000000" then
                            a_is_inf <= '1'; a_is_nan <= '0';
                        else
                            a_is_nan <= '1'; a_is_inf <= '0';
                        end if;
                        a_is_zero <= '0'; a_is_denorm <= '0';
                    elsif a(30 downto 23) = "00000000" then
                        if a(22 downto 0) = "00000000000000000000000" then
                            a_is_zero <= '1'; a_is_denorm <= '0';
                        else
                            a_is_zero <= '0'; a_is_denorm <= '1';
                        end if;
                        a_is_inf <= '0'; a_is_nan <= '0';
                    else
                        a_is_zero <= '0'; a_is_denorm <= '0';
                        a_is_inf  <= '0'; a_is_nan   <= '0';
                    end if;

                    -- Detect special cases for operand b
                    if b(30 downto 23) = "11111111" then
                        if b(22 downto 0) = "00000000000000000000000" then
                            b_is_inf <= '1'; b_is_nan <= '0';
                        else
                            b_is_nan <= '1'; b_is_inf <= '0';
                        end if;
                        b_is_zero <= '0'; b_is_denorm <= '0';
                    elsif b(30 downto 23) = "00000000" then
                        if b(22 downto 0) = "00000000000000000000000" then
                            b_is_zero <= '1'; b_is_denorm <= '0';
                        else
                            b_is_zero <= '0'; b_is_denorm <= '1';
                        end if;
                        b_is_inf <= '0'; b_is_nan <= '0';
                    else
                        b_is_zero <= '0'; b_is_denorm <= '0';
                        b_is_inf  <= '0'; b_is_nan   <= '0';
                    end if;

                -- State 1: Normalize mantissas and compute unbiased exponents
                when "001" =>
                    -- Operand a
                    if a_is_nan = '1' or a_is_inf = '1' or a_is_zero = '1' then
                        a_norm_mant <= (others => '0');
                        a_unb_exp   <= (others => '0');
                    elsif a_is_denorm = '1' then
                        in24_a := '0' & a_mantissa;
                        lzc_a := count_leading_zeros_24(in24_a);
                        a_norm_mant <= STD_LOGIC_VECTOR(shift_left(unsigned(in24_a), to_integer(lzc_a)));
                        a_unb_exp   <= STD_LOGIC_VECTOR(to_signed((-126) - to_integer(lzc_a), 10));
                    else
                        a_norm_mant <= '1' & a_mantissa;
                        a_unb_exp   <= STD_LOGIC_VECTOR(to_signed(to_integer(unsigned(a_exponent(7 downto 0))) - 127, 10));
                    end if;

                    -- Operand b
                    if b_is_nan = '1' or b_is_inf = '1' or b_is_zero = '1' then
                        b_norm_mant <= (others => '0');
                        b_unb_exp   <= (others => '0');
                    elsif b_is_denorm = '1' then
                        in24_b := '0' & b_mantissa;
                        lzc_b := count_leading_zeros_24(in24_b);
                        b_norm_mant <= STD_LOGIC_VECTOR(shift_left(unsigned(in24_b), to_integer(lzc_b)));
                        b_unb_exp   <= STD_LOGIC_VECTOR(to_signed((-126) - to_integer(lzc_b), 10));
                    else
                        b_norm_mant <= '1' & b_mantissa;
                        b_unb_exp   <= STD_LOGIC_VECTOR(to_signed(to_integer(unsigned(b_exponent(7 downto 0))) - 127, 10));
                    end if;

                -- State 2: Multiply mantissas, compute sign and exponent sum
                when "010" =>
                    product      <= "00" & STD_LOGIC_VECTOR(unsigned(a_norm_mant) * unsigned(b_norm_mant));
                    z_sign       <= a_sign xor b_sign;
                    exp_sum_unb  <= STD_LOGIC_VECTOR(signed(a_unb_exp) + signed(b_unb_exp));

                -- State 3: Normalize product and extract guard, round, sticky
                when "011" =>
                    if product(47) = '1' then
                        z_mantissa  <= product(47 downto 24);
                        guard_bit   <= product(23);
                        round_bit   <= product(22);
                        if product(21 downto 0) = "0000000000000000000000" then
                            sticky <= '0';
                        else
                            sticky <= '1';
                        end if;
                        z_exponent <= STD_LOGIC_VECTOR(signed(exp_sum_unb) + to_signed(1, 10));
                    else
                        z_mantissa  <= product(46 downto 23);
                        guard_bit   <= product(22);
                        round_bit   <= product(21);
                        if product(20 downto 0) = "000000000000000000000" then
                            sticky <= '0';
                        else
                            sticky <= '1';
                        end if;
                        z_exponent <= exp_sum_unb;
                    end if;

                -- State 4: Round mantissa and adjust exponent if needed
                when "100" =>
                    round_up := (guard_bit = '1') and (round_bit = '1' or sticky = '1' or z_mantissa(0) = '1');
                    if round_up then
                        mant_post_25 := STD_LOGIC_VECTOR(unsigned('0' & z_mantissa) + 1);
                        if mant_post_25(24) = '1' then
                            -- Rounding overflow
                            z_mantissa <= '1' & "00000000000000000000000";
                            z_exponent <= STD_LOGIC_VECTOR(signed(z_exponent) + to_signed(1, 10));
                        else
                            z_mantissa <= mant_post_25(23 downto 0);
                            -- z_exponent unchanged
                        end if;
                    end if;
                    -- if no rounding, z_mantissa and z_exponent keep their values

                -- State 5: Finalize result with special cases and exception handling
                when "101" =>
                    biased_exp := to_integer(signed(z_exponent)) + 127;

                    if a_is_nan = '1' or b_is_nan = '1' then
                        z <= '0' & "11111111" & "10000000000000000000000";  -- quiet NaN
                    elsif (a_is_inf = '1' and b_is_zero = '1') or (a_is_zero = '1' and b_is_inf = '1') then
                        z <= '0' & "11111111" & "10000000000000000000000";  -- invalid -> NaN
                    elsif a_is_inf = '1' or b_is_inf = '1' then
                        z <= z_sign & "11111111" & "00000000000000000000000"; -- infinity
                    elsif a_is_zero = '1' or b_is_zero = '1' then
                        z <= z_sign & "00000000" & "00000000000000000000000"; -- zero
                    else
                        if biased_exp >= 255 then
                            z <= z_sign & "11111111" & "00000000000000000000000"; -- overflow to infinity
                        elsif biased_exp <= 0 then
                            z <= z_sign & "00000000" & "00000000000000000000000"; -- underflow to zero
                        else
                            z <= z_sign & STD_LOGIC_VECTOR(to_unsigned(biased_exp, 8)) & z_mantissa(22 downto 0);
                        end if;
                    end if;

                when others =>
                    null;
            end case;

            -- Counter update (wraps from 5 back to 0)
            if counter = "101" then
                counter <= (others => '0');
            else
                counter <= STD_LOGIC_VECTOR(unsigned(counter) + 1);
            end if;
        end if;
    end process;

end Behavioral;