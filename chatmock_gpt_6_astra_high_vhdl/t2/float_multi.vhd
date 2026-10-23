library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_multi is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic_vector(31 downto 0);
        b   : in  std_logic_vector(31 downto 0);
        z   : out std_logic_vector(31 downto 0)
    );
end entity float_multi;

architecture rtl of float_multi is
    signal counter : unsigned(2 downto 0);

    signal a_mantissa : unsigned(23 downto 0);
    signal b_mantissa : unsigned(23 downto 0);
    signal z_mantissa : unsigned(23 downto 0);

    signal a_exponent : signed(9 downto 0);
    signal b_exponent : signed(9 downto 0);
    signal z_exponent : signed(9 downto 0);

    signal a_sign : std_logic;
    signal b_sign : std_logic;
    signal z_sign : std_logic;

    signal product   : unsigned(49 downto 0);
    signal guard_bit : std_logic;
    signal round_bit : std_logic;
    signal sticky    : std_logic;

    signal special_valid  : std_logic;
    signal special_result : std_logic_vector(31 downto 0);
    signal result_reg     : std_logic_vector(31 downto 0);

    constant QUIET_NAN : std_logic_vector(31 downto 0) := x"7FC00000";
begin
    process (clk, rst)
        variable am_v      : unsigned(23 downto 0);
        variable bm_v      : unsigned(23 downto 0);
        variable ae_v      : integer range -1024 to 1023;
        variable be_v      : integer range -1024 to 1023;
        variable exp_v     : integer range -1024 to 1023;
        variable shift_v   : integer range 0 to 1024;
        variable shifted_v : unsigned(49 downto 0);
        variable rounded_v : unsigned(24 downto 0);
        variable guard_v   : std_logic;
        variable round_v   : std_logic;
        variable sticky_v  : std_logic;
        variable sign_v    : std_logic;
        variable result_v  : std_logic_vector(31 downto 0);
        variable a_nan_v   : boolean;
        variable b_nan_v   : boolean;
        variable a_inf_v   : boolean;
        variable b_inf_v   : boolean;
        variable a_zero_v  : boolean;
        variable b_zero_v  : boolean;
    begin
        if rst = '1' then
            counter        <= (others => '0');
            a_mantissa     <= (others => '0');
            b_mantissa     <= (others => '0');
            z_mantissa     <= (others => '0');
            a_exponent     <= (others => '0');
            b_exponent     <= (others => '0');
            z_exponent     <= (others => '0');
            a_sign         <= '0';
            b_sign         <= '0';
            z_sign         <= '0';
            product        <= (others => '0');
            guard_bit      <= '0';
            round_bit      <= '0';
            sticky         <= '0';
            special_valid  <= '0';
            special_result <= (others => '0');
            result_reg     <= (others => '0');
            z              <= (others => '0');

        elsif rising_edge(clk) then
            counter <= counter + to_unsigned(1, counter'length);

            case to_integer(counter) is
                when 0 =>
                    -- Capture a new operand pair every eight clocks.
                    a_mantissa <= unsigned('0' & a(22 downto 0));
                    b_mantissa <= unsigned('0' & b(22 downto 0));

                    a_exponent <= to_signed(
                        to_integer(unsigned(a(30 downto 23))) - 127, 10);
                    b_exponent <= to_signed(
                        to_integer(unsigned(b(30 downto 23))) - 127, 10);

                    a_sign <= a(31);
                    b_sign <= b(31);

                    special_valid <= '0';
                    guard_bit <= '0';
                    round_bit <= '0';
                    sticky    <= '0';

                when 1 =>
                    sign_v := a_sign xor b_sign;
                    z_sign <= sign_v;

                    a_nan_v := (a_exponent = to_signed(128, 10)) and
                               (a_mantissa /= to_unsigned(0, 24));
                    b_nan_v := (b_exponent = to_signed(128, 10)) and
                               (b_mantissa /= to_unsigned(0, 24));

                    a_inf_v := (a_exponent = to_signed(128, 10)) and
                               (a_mantissa = to_unsigned(0, 24));
                    b_inf_v := (b_exponent = to_signed(128, 10)) and
                               (b_mantissa = to_unsigned(0, 24));

                    a_zero_v := (a_exponent = to_signed(-127, 10)) and
                                (a_mantissa = to_unsigned(0, 24));
                    b_zero_v := (b_exponent = to_signed(-127, 10)) and
                                (b_mantissa = to_unsigned(0, 24));

                    result_v := (others => '0');
                    result_v(31) := sign_v;

                    if a_nan_v or b_nan_v or
                       (a_inf_v and b_zero_v) or
                       (b_inf_v and a_zero_v) then
                        special_valid  <= '1';
                        special_result <= QUIET_NAN;
                    elsif a_inf_v or b_inf_v then
                        result_v(30 downto 23) := (others => '1');
                        special_valid  <= '1';
                        special_result <= result_v;
                    elsif a_zero_v or b_zero_v then
                        special_valid  <= '1';
                        special_result <= result_v;
                    else
                        special_valid <= '0';
                    end if;

                    -- Subnormals have no implicit leading one.
                    if a_exponent = to_signed(-127, 10) then
                        a_exponent <= to_signed(-126, 10);
                    else
                        a_mantissa(23) <= '1';
                    end if;

                    if b_exponent = to_signed(-127, 10) then
                        b_exponent <= to_signed(-126, 10);
                    else
                        b_mantissa(23) <= '1';
                    end if;

                when 2 =>
                    -- Normalize finite, nonzero input significands.
                    am_v := a_mantissa;
                    bm_v := b_mantissa;
                    ae_v := to_integer(a_exponent);
                    be_v := to_integer(b_exponent);

                    for i in 0 to 22 loop
                        if am_v(23) = '0' and
                           am_v /= to_unsigned(0, 24) then
                            am_v := shift_left(am_v, 1);
                            ae_v := ae_v - 1;
                        end if;

                        if bm_v(23) = '0' and
                           bm_v /= to_unsigned(0, 24) then
                            bm_v := shift_left(bm_v, 1);
                            be_v := be_v - 1;
                        end if;
                    end loop;

                    a_mantissa <= am_v;
                    b_mantissa <= bm_v;
                    a_exponent <= to_signed(ae_v, 10);
                    b_exponent <= to_signed(be_v, 10);

                when 3 =>
                    product    <= resize(a_mantissa * b_mantissa, 50);
                    z_exponent <= a_exponent + b_exponent;

                when 4 =>
                    -- Select the final precision before rounding, including
                    -- any extra right shift required for gradual underflow.
                    exp_v := to_integer(z_exponent);

                    if product(47) = '1' then
                        shift_v := 24;
                        exp_v   := exp_v + 1;
                    else
                        shift_v := 23;
                    end if;

                    if exp_v < -126 then
                        shift_v := shift_v + (-126 - exp_v);
                        exp_v   := -126;
                    end if;

                    shifted_v := shift_right(product, shift_v);
                    guard_v   := '0';
                    round_v   := '0';
                    sticky_v  := '0';

                    if shift_v >= 1 and shift_v <= 50 then
                        guard_v := product(shift_v - 1);
                    end if;

                    if shift_v >= 2 and shift_v <= 51 then
                        round_v := product(shift_v - 2);
                    end if;

                    for i in 0 to 49 loop
                        if i < shift_v - 2 then
                            sticky_v := sticky_v or product(i);
                        end if;
                    end loop;

                    z_mantissa <= shifted_v(23 downto 0);
                    z_exponent <= to_signed(exp_v, 10);
                    guard_bit  <= guard_v;
                    round_bit  <= round_v;
                    sticky     <= sticky_v;

                when 5 =>
                    -- IEEE-754 round to nearest, ties to even.
                    rounded_v := resize(z_mantissa, 25);

                    if guard_bit = '1' and
                       (round_bit = '1' or sticky = '1' or
                        z_mantissa(0) = '1') then
                        rounded_v := rounded_v + to_unsigned(1, 25);
                    end if;

                    if rounded_v(24) = '1' then
                        z_mantissa <= rounded_v(24 downto 1);
                        z_exponent <= z_exponent + to_signed(1, 10);
                    else
                        z_mantissa <= rounded_v(23 downto 0);
                    end if;

                when 6 =>
                    result_v := (others => '0');
                    result_v(31) := z_sign;
                    exp_v := to_integer(z_exponent);

                    if special_valid = '1' then
                        result_v := special_result;
                    elsif exp_v > 127 then
                        -- Overflow rounds to signed infinity.
                        result_v(30 downto 23) := (others => '1');
                    elsif z_mantissa = to_unsigned(0, 24) then
                        -- Preserve the sign of an exact or rounded zero.
                        null;
                    elsif exp_v = -126 and z_mantissa(23) = '0' then
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    else
                        result_v(30 downto 23) :=
                            std_logic_vector(to_unsigned(exp_v + 127, 8));
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    end if;

                    result_reg <= result_v;

                when 7 =>
                    z <= result_reg;

                when others =>
                    counter <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
