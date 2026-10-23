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

    signal special_case   : std_logic;
    signal special_result : std_logic_vector(31 downto 0);
    signal result_reg     : std_logic_vector(31 downto 0);

    constant ZERO_MANTISSA : unsigned(23 downto 0) := (others => '0');
    constant ZERO_FRACTION : unsigned(22 downto 0) := (others => '0');

begin
    -- Operands are sampled at counter = 0. The corresponding result is
    -- published at counter = 7. Rounding is round-to-nearest, ties-to-even.
    process (clk, rst)
        variable ma_v       : unsigned(23 downto 0);
        variable mb_v       : unsigned(23 downto 0);
        variable ea_v       : integer;
        variable eb_v       : integer;
        variable ez_v       : integer;
        variable shift_v    : integer;
        variable shifted_v  : unsigned(49 downto 0);
        variable rounded_v  : unsigned(24 downto 0);
        variable guard_v    : std_logic;
        variable round_v    : std_logic;
        variable sticky_v   : std_logic;
        variable sign_v     : std_logic;
        variable result_v   : std_logic_vector(31 downto 0);
        variable a_nan_v    : boolean;
        variable b_nan_v    : boolean;
        variable a_inf_v    : boolean;
        variable b_inf_v    : boolean;
        variable a_zero_v   : boolean;
        variable b_zero_v   : boolean;
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
            special_case   <= '0';
            special_result <= (others => '0');
            result_reg     <= (others => '0');
            z              <= (others => '0');

        elsif rising_edge(clk) then
            counter <= counter + to_unsigned(1, counter'length);

            case to_integer(counter) is
                when 0 =>
                    a_sign <= a(31);
                    b_sign <= b(31);

                    if a(30 downto 23) = x"00" then
                        a_mantissa <= unsigned('0' & a(22 downto 0));
                        a_exponent <= to_signed(-126, 10);
                    else
                        a_mantissa <= unsigned('1' & a(22 downto 0));
                        a_exponent <= to_signed(
                            to_integer(unsigned(a(30 downto 23))) - 127,
                            10
                        );
                    end if;

                    if b(30 downto 23) = x"00" then
                        b_mantissa <= unsigned('0' & b(22 downto 0));
                        b_exponent <= to_signed(-126, 10);
                    else
                        b_mantissa <= unsigned('1' & b(22 downto 0));
                        b_exponent <= to_signed(
                            to_integer(unsigned(b(30 downto 23))) - 127,
                            10
                        );
                    end if;

                    special_case   <= '0';
                    special_result <= (others => '0');

                when 1 =>
                    sign_v := a_sign xor b_sign;

                    a_nan_v := (a_exponent = to_signed(128, 10)) and
                               (a_mantissa(22 downto 0) /= ZERO_FRACTION);
                    b_nan_v := (b_exponent = to_signed(128, 10)) and
                               (b_mantissa(22 downto 0) /= ZERO_FRACTION);
                    a_inf_v := (a_exponent = to_signed(128, 10)) and
                               (a_mantissa(22 downto 0) = ZERO_FRACTION);
                    b_inf_v := (b_exponent = to_signed(128, 10)) and
                               (b_mantissa(22 downto 0) = ZERO_FRACTION);
                    a_zero_v := (a_mantissa = ZERO_MANTISSA);
                    b_zero_v := (b_mantissa = ZERO_MANTISSA);

                    result_v := (others => '0');
                    result_v(31) := sign_v;

                    if a_nan_v or b_nan_v then
                        special_case   <= '1';
                        special_result <= x"7FC00000";
                    elsif (a_inf_v and b_zero_v) or
                          (b_inf_v and a_zero_v) then
                        special_case   <= '1';
                        special_result <= x"7FC00000";
                    elsif a_inf_v or b_inf_v then
                        result_v(30 downto 23) := (others => '1');
                        special_case   <= '1';
                        special_result <= result_v;
                    elsif a_zero_v or b_zero_v then
                        special_case   <= '1';
                        special_result <= result_v;
                    else
                        special_case <= '0';
                    end if;

                when 2 =>
                    ma_v := a_mantissa;
                    mb_v := b_mantissa;
                    ea_v := to_integer(a_exponent);
                    eb_v := to_integer(b_exponent);

                    -- Bounded normalization also handles all subnormal inputs.
                    for i in 0 to 22 loop
                        if (ma_v /= ZERO_MANTISSA) and (ma_v(23) = '0') then
                            ma_v := shift_left(ma_v, 1);
                            ea_v := ea_v - 1;
                        end if;
                        if (mb_v /= ZERO_MANTISSA) and (mb_v(23) = '0') then
                            mb_v := shift_left(mb_v, 1);
                            eb_v := eb_v - 1;
                        end if;
                    end loop;

                    a_mantissa <= ma_v;
                    b_mantissa <= mb_v;
                    a_exponent <= to_signed(ea_v, 10);
                    b_exponent <= to_signed(eb_v, 10);

                when 3 =>
                    product <= resize(a_mantissa * b_mantissa, 50);
                    z_sign <= a_sign xor b_sign;
                    z_exponent <= a_exponent + b_exponent;

                when 4 =>
                    ez_v := to_integer(z_exponent);

                    if product(47) = '1' then
                        shift_v := 24;
                        ez_v := ez_v + 1;
                    else
                        shift_v := 23;
                    end if;

                    -- Include gradual underflow in the same rounding step
                    -- to avoid double rounding of subnormal results.
                    if ez_v < -126 then
                        shift_v := shift_v + (-126 - ez_v);
                        ez_v := -126;
                    end if;

                    shifted_v := shift_right(product, shift_v);
                    guard_v  := '0';
                    round_v  := '0';
                    sticky_v := '0';

                    for i in 0 to 49 loop
                        if i = shift_v - 1 then
                            guard_v := product(i);
                        elsif i = shift_v - 2 then
                            round_v := product(i);
                        elsif i < shift_v - 2 then
                            sticky_v := sticky_v or product(i);
                        end if;
                    end loop;

                    z_mantissa <= shifted_v(23 downto 0);
                    z_exponent <= to_signed(ez_v, 10);
                    guard_bit  <= guard_v;
                    round_bit  <= round_v;
                    sticky     <= sticky_v;

                when 5 =>
                    rounded_v := resize(z_mantissa, 25);
                    ez_v := to_integer(z_exponent);

                    if (guard_bit = '1') and
                       ((round_bit = '1') or
                        (sticky = '1') or
                        (z_mantissa(0) = '1')) then
                        rounded_v := rounded_v + to_unsigned(1, 25);
                    end if;

                    if rounded_v(24) = '1' then
                        z_mantissa <= rounded_v(24 downto 1);
                        ez_v := ez_v + 1;
                    else
                        z_mantissa <= rounded_v(23 downto 0);
                    end if;

                    z_exponent <= to_signed(ez_v, 10);

                when 6 =>
                    result_v := (others => '0');
                    result_v(31) := z_sign;
                    ez_v := to_integer(z_exponent);

                    if special_case = '1' then
                        result_v := special_result;
                    elsif ez_v > 127 then
                        result_v(30 downto 23) := (others => '1');
                    elsif z_mantissa = ZERO_MANTISSA then
                        null;
                    elsif (ez_v = -126) and (z_mantissa(23) = '0') then
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    else
                        result_v(30 downto 23) :=
                            std_logic_vector(to_unsigned(ez_v + 127, 8));
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
