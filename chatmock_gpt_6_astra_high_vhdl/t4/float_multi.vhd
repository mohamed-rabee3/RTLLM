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
    signal packed_result  : std_logic_vector(31 downto 0);

    constant QUIET_NAN : std_logic_vector(31 downto 0) := x"7FC00000";

    function or_reduce(v : unsigned) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in v'range loop
            result := result or v(i);
        end loop;
        return result;
    end function;
begin

    -- Operands are sampled at counter = 0. The result is registered at
    -- counter = 7. Transactions repeat every eight clocks.
    process (clk, rst)
        variable ma             : unsigned(23 downto 0);
        variable mb             : unsigned(23 downto 0);
        variable ea             : integer range -512 to 511;
        variable eb             : integer range -512 to 511;
        variable shift_count    : integer range 0 to 511;
        variable extended_value : unsigned(26 downto 0);
        variable rounded_value  : unsigned(24 downto 0);
        variable result_value   : std_logic_vector(31 downto 0);
        variable a_is_nan       : boolean;
        variable b_is_nan       : boolean;
        variable a_is_inf       : boolean;
        variable b_is_inf       : boolean;
        variable a_is_zero      : boolean;
        variable b_is_zero      : boolean;
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
            packed_result  <= (others => '0');
            z              <= (others => '0');

        elsif rising_edge(clk) then
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

                    special_valid <= '0';
                    counter <= to_unsigned(1, 3);

                when 1 =>
                    z_sign <= a_sign xor b_sign;

                    a_is_nan := (a_exponent = to_signed(128, 10)) and
                                (a_mantissa(22 downto 0) /=
                                 to_unsigned(0, 23));
                    b_is_nan := (b_exponent = to_signed(128, 10)) and
                                (b_mantissa(22 downto 0) /=
                                 to_unsigned(0, 23));

                    a_is_inf := (a_exponent = to_signed(128, 10)) and
                                (a_mantissa(22 downto 0) =
                                 to_unsigned(0, 23));
                    b_is_inf := (b_exponent = to_signed(128, 10)) and
                                (b_mantissa(22 downto 0) =
                                 to_unsigned(0, 23));

                    a_is_zero := a_mantissa = to_unsigned(0, 24);
                    b_is_zero := b_mantissa = to_unsigned(0, 24);

                    result_value := (others => '0');
                    result_value(31) := a_sign xor b_sign;

                    if a_is_nan or b_is_nan or
                       (a_is_inf and b_is_zero) or
                       (b_is_inf and a_is_zero) then
                        special_valid  <= '1';
                        special_result <= QUIET_NAN;

                    elsif a_is_inf or b_is_inf then
                        result_value(30 downto 23) := (others => '1');
                        special_valid  <= '1';
                        special_result <= result_value;

                    elsif a_is_zero or b_is_zero then
                        special_valid  <= '1';
                        special_result <= result_value;

                    else
                        special_valid <= '0';

                        ma := a_mantissa;
                        mb := b_mantissa;
                        ea := to_integer(a_exponent);
                        eb := to_integer(b_exponent);

                        -- Normalize subnormal operands without losing bits.
                        for i in 0 to 22 loop
                            if ma(23) = '0' then
                                ma := shift_left(ma, 1);
                                ea := ea - 1;
                            end if;
                            if mb(23) = '0' then
                                mb := shift_left(mb, 1);
                                eb := eb - 1;
                            end if;
                        end loop;

                        a_mantissa <= ma;
                        b_mantissa <= mb;
                        a_exponent <= to_signed(ea, 10);
                        b_exponent <= to_signed(eb, 10);
                    end if;

                    counter <= to_unsigned(2, 3);

                when 2 =>
                    product    <= resize(a_mantissa * b_mantissa, 50);
                    z_exponent <= a_exponent + b_exponent;
                    counter    <= to_unsigned(3, 3);

                when 3 =>
                    -- Preserve guard, round, and sticky bits from the
                    -- exact 48-bit significand product.
                    if product(47) = '1' then
                        z_mantissa <= product(47 downto 24);
                        guard_bit  <= product(23);
                        round_bit  <= product(22);
                        sticky     <= or_reduce(product(21 downto 0));
                        z_exponent <= z_exponent + to_signed(1, 10);
                    else
                        z_mantissa <= product(46 downto 23);
                        guard_bit  <= product(22);
                        round_bit  <= product(21);
                        sticky     <= or_reduce(product(20 downto 0));
                    end if;

                    counter <= to_unsigned(4, 3);

                when 4 =>
                    -- Gradual underflow: right-shift with sticky-bit
                    -- accumulation before performing the single rounding.
                    if z_exponent < to_signed(-126, 10) then
                        shift_count := -126 - to_integer(z_exponent);
                        extended_value :=
                            z_mantissa & guard_bit & round_bit & sticky;

                        for i in 1 to 27 loop
                            if i <= shift_count then
                                extended_value :=
                                    '0' & extended_value(26 downto 2) &
                                    (extended_value(1) or extended_value(0));
                            end if;
                        end loop;

                        z_mantissa <= extended_value(26 downto 3);
                        guard_bit  <= extended_value(2);
                        round_bit  <= extended_value(1);
                        sticky     <= extended_value(0);
                        z_exponent <= to_signed(-126, 10);
                    end if;

                    counter <= to_unsigned(5, 3);

                when 5 =>
                    -- IEEE-754 round to nearest, ties to even.
                    rounded_value := resize(z_mantissa, 25);

                    if guard_bit = '1' and
                       (round_bit = '1' or sticky = '1' or
                        z_mantissa(0) = '1') then
                        rounded_value :=
                            rounded_value + to_unsigned(1, 25);
                    end if;

                    if rounded_value(24) = '1' then
                        z_mantissa <= rounded_value(24 downto 1);
                        z_exponent <= z_exponent + to_signed(1, 10);
                    else
                        z_mantissa <= rounded_value(23 downto 0);
                    end if;

                    counter <= to_unsigned(6, 3);

                when 6 =>
                    result_value := (others => '0');
                    result_value(31) := z_sign;

                    if special_valid = '1' then
                        result_value := special_result;

                    elsif z_exponent > to_signed(127, 10) then
                        -- Overflow rounds to signed infinity.
                        result_value(30 downto 23) := (others => '1');

                    elsif z_mantissa = to_unsigned(0, 24) then
                        -- Retain the sign of an exact or rounded zero.
                        null;

                    elsif z_exponent = to_signed(-126, 10) and
                          z_mantissa(23) = '0' then
                        result_value(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));

                    else
                        result_value(30 downto 23) :=
                            std_logic_vector(to_unsigned(
                                to_integer(z_exponent) + 127, 8));
                        result_value(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    end if;

                    packed_result <= result_value;
                    counter <= to_unsigned(7, 3);

                when 7 =>
                    z <= packed_result;
                    counter <= (others => '0');

                when others =>
                    counter <= (others => '0');
            end case;
        end if;
    end process;

end architecture rtl;
