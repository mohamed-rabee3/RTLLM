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

    signal a_is_nan, b_is_nan   : std_logic;
    signal a_is_inf, b_is_inf   : std_logic;
    signal a_is_zero, b_is_zero : std_logic;

    signal special_valid  : std_logic;
    signal special_result : std_logic_vector(31 downto 0);

    -- Right shift with all discarded bits accumulated into bit zero.
    function shift_right_jam(
        value  : unsigned(49 downto 0);
        amount : natural
    ) return unsigned is
        variable result_value : unsigned(49 downto 0);
        variable discarded    : std_logic;
    begin
        result_value := (others => '0');
        discarded := '0';

        if amount = 0 then
            result_value := value;
        elsif amount >= 50 then
            for i in 0 to 49 loop
                discarded := discarded or value(i);
            end loop;
            result_value(0) := discarded;
        else
            result_value := shift_right(value, amount);
            for i in 0 to 49 loop
                if i < amount then
                    discarded := discarded or value(i);
                end if;
            end loop;
            result_value(0) := result_value(0) or discarded;
        end if;

        return result_value;
    end function;

begin
    process(clk, rst)
        variable ma, mb       : unsigned(23 downto 0);
        variable ea, eb       : signed(9 downto 0);
        variable rounded     : unsigned(24 downto 0);
        variable sticky_v    : std_logic;
        variable result_v    : std_logic_vector(31 downto 0);
        variable shift_count : natural;
    begin
        if rst = '1' then
            counter <= (others => '0');
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
            a_is_nan <= '0';
            b_is_nan <= '0';
            a_is_inf <= '0';
            b_is_inf <= '0';
            a_is_zero <= '0';
            b_is_zero <= '0';
            special_valid <= '0';
            special_result <= (others => '0');
            z <= (others => '0');

        elsif rising_edge(clk) then
            counter <= counter + 1;

            case to_integer(counter) is
                when 0 =>
                    -- Capture a new operand pair every eight clocks.
                    a_sign <= a(31);
                    b_sign <= b(31);

                    if unsigned(a(30 downto 23)) = 0 then
                        a_mantissa <= unsigned('0' & a(22 downto 0));
                        a_exponent <= to_signed(-126, 10);
                    else
                        a_mantissa <= unsigned('1' & a(22 downto 0));
                        a_exponent <=
                            to_signed(to_integer(unsigned(a(30 downto 23))) - 127, 10);
                    end if;

                    if unsigned(b(30 downto 23)) = 0 then
                        b_mantissa <= unsigned('0' & b(22 downto 0));
                        b_exponent <= to_signed(-126, 10);
                    else
                        b_mantissa <= unsigned('1' & b(22 downto 0));
                        b_exponent <=
                            to_signed(to_integer(unsigned(b(30 downto 23))) - 127, 10);
                    end if;

                    a_is_nan <= '0';
                    b_is_nan <= '0';
                    a_is_inf <= '0';
                    b_is_inf <= '0';
                    a_is_zero <= '0';
                    b_is_zero <= '0';

                    if a(30 downto 23) = x"FF" then
                        if unsigned(a(22 downto 0)) = 0 then
                            a_is_inf <= '1';
                        else
                            a_is_nan <= '1';
                        end if;
                    elsif unsigned(a(30 downto 0)) = 0 then
                        a_is_zero <= '1';
                    end if;

                    if b(30 downto 23) = x"FF" then
                        if unsigned(b(22 downto 0)) = 0 then
                            b_is_inf <= '1';
                        else
                            b_is_nan <= '1';
                        end if;
                    elsif unsigned(b(30 downto 0)) = 0 then
                        b_is_zero <= '1';
                    end if;

                when 1 =>
                    z_sign <= a_sign xor b_sign;
                    special_valid <= '1';
                    result_v := (others => '0');
                    result_v(31) := a_sign xor b_sign;

                    if (a_is_nan = '1') or (b_is_nan = '1') or
                       ((a_is_inf = '1') and (b_is_zero = '1')) or
                       ((b_is_inf = '1') and (a_is_zero = '1')) then
                        result_v := x"7FC00000";
                    elsif (a_is_inf = '1') or (b_is_inf = '1') then
                        result_v(30 downto 23) := x"FF";
                    elsif (a_is_zero = '1') or (b_is_zero = '1') then
                        null;
                    else
                        special_valid <= '0';
                    end if;
                    special_result <= result_v;

                    -- Normalize finite, nonzero subnormal inputs.
                    ma := a_mantissa;
                    mb := b_mantissa;
                    ea := a_exponent;
                    eb := b_exponent;

                    for i in 0 to 22 loop
                        if (ma /= 0) and (ma(23) = '0') then
                            ma := shift_left(ma, 1);
                            ea := ea - 1;
                        end if;
                        if (mb /= 0) and (mb(23) = '0') then
                            mb := shift_left(mb, 1);
                            eb := eb - 1;
                        end if;
                    end loop;

                    a_mantissa <= ma;
                    b_mantissa <= mb;
                    a_exponent <= ea;
                    b_exponent <= eb;

                when 2 =>
                    product <= resize(a_mantissa * b_mantissa, 50);
                    z_exponent <= a_exponent + b_exponent;

                when 3 =>
                    -- Align the leading significand bit with product bit 46.
                    if product(47) = '1' then
                        product <= shift_right_jam(product, 1);
                        z_exponent <= z_exponent + 1;
                    end if;

                when 4 =>
                    -- Gradual underflow, preserving all rounding information.
                    if z_exponent < to_signed(-126, 10) then
                        shift_count := natural(-126 - to_integer(z_exponent));
                        product <= shift_right_jam(product, shift_count);
                        z_exponent <= to_signed(-126, 10);
                    end if;

                when 5 =>
                    z_mantissa <= product(46 downto 23);
                    guard_bit <= product(22);
                    round_bit <= product(21);

                    sticky_v := '0';
                    for i in 0 to 20 loop
                        sticky_v := sticky_v or product(i);
                    end loop;
                    sticky <= sticky_v;

                when 6 =>
                    -- IEEE-754 round to nearest, ties to even.
                    rounded := resize(z_mantissa, 25);
                    if (guard_bit = '1') and
                       ((round_bit = '1') or (sticky = '1') or
                        (z_mantissa(0) = '1')) then
                        rounded := rounded + 1;
                    end if;

                    if rounded(24) = '1' then
                        z_mantissa <= rounded(24 downto 1);
                        z_exponent <= z_exponent + 1;
                    else
                        z_mantissa <= rounded(23 downto 0);
                    end if;

                when 7 =>
                    result_v := (others => '0');
                    result_v(31) := z_sign;

                    if special_valid = '1' then
                        result_v := special_result;
                    elsif z_exponent > to_signed(127, 10) then
                        result_v(30 downto 23) := x"FF";
                    elsif z_mantissa = 0 then
                        null;
                    elsif (z_exponent = to_signed(-126, 10)) and
                          (z_mantissa(23) = '0') then
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    else
                        result_v(30 downto 23) :=
                            std_logic_vector(
                                to_unsigned(to_integer(z_exponent) + 127, 8)
                            );
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    end if;

                    z <= result_v;

                when others =>
                    counter <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
