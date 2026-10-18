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

    signal a_nan, b_nan   : std_logic;
    signal a_inf, b_inf   : std_logic;
    signal a_zero, b_zero : std_logic;

    signal special_case   : std_logic;
    signal special_result : std_logic_vector(31 downto 0);
    signal packed_result  : std_logic_vector(31 downto 0);

begin
    -- An operation occupies eight clocks. Inputs are sampled when counter
    -- is zero; the corresponding result is registered when counter is seven.
    process (clk, rst)
        variable ma, mb       : unsigned(23 downto 0);
        variable ea, eb       : integer;
        variable p           : unsigned(49 downto 0);
        variable rounded     : unsigned(24 downto 0);
        variable shift_count : integer;
        variable lost_bits   : std_logic;
        variable sticky_v    : std_logic;
        variable result_v    : std_logic_vector(31 downto 0);
        variable exponent_v  : integer;
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
            a_nan          <= '0';
            b_nan          <= '0';
            a_inf          <= '0';
            b_inf          <= '0';
            a_zero         <= '0';
            b_zero         <= '0';
            special_case   <= '0';
            special_result <= (others => '0');
            packed_result  <= (others => '0');
            z              <= (others => '0');

        elsif rising_edge(clk) then
            counter <= counter + 1;

            case counter is
                when "000" =>
                    a_sign <= a(31);
                    b_sign <= b(31);
                    z_sign <= a(31) xor b(31);

                    a_mantissa(22 downto 0) <= unsigned(a(22 downto 0));
                    b_mantissa(22 downto 0) <= unsigned(b(22 downto 0));

                    if unsigned(a(30 downto 23)) = 0 then
                        a_mantissa(23) <= '0';
                        a_exponent <= to_signed(-126, 10);
                    else
                        a_mantissa(23) <= '1';
                        a_exponent <= to_signed(
                            to_integer(unsigned(a(30 downto 23))) - 127, 10);
                    end if;

                    if unsigned(b(30 downto 23)) = 0 then
                        b_mantissa(23) <= '0';
                        b_exponent <= to_signed(-126, 10);
                    else
                        b_mantissa(23) <= '1';
                        b_exponent <= to_signed(
                            to_integer(unsigned(b(30 downto 23))) - 127, 10);
                    end if;

                    a_nan  <= '0';
                    b_nan  <= '0';
                    a_inf  <= '0';
                    b_inf  <= '0';
                    a_zero <= '0';
                    b_zero <= '0';

                    if a(30 downto 23) = x"FF" then
                        if unsigned(a(22 downto 0)) = 0 then
                            a_inf <= '1';
                        else
                            a_nan <= '1';
                        end if;
                    elsif unsigned(a(30 downto 0)) = 0 then
                        a_zero <= '1';
                    end if;

                    if b(30 downto 23) = x"FF" then
                        if unsigned(b(22 downto 0)) = 0 then
                            b_inf <= '1';
                        else
                            b_nan <= '1';
                        end if;
                    elsif unsigned(b(30 downto 0)) = 0 then
                        b_zero <= '1';
                    end if;

                when "001" =>
                    special_case <= '1';
                    result_v := (others => '0');

                    if a_nan = '1' or b_nan = '1' or
                       (a_inf = '1' and b_zero = '1') or
                       (b_inf = '1' and a_zero = '1') then
                        result_v := x"7FC00000";
                    elsif a_inf = '1' or b_inf = '1' then
                        result_v := x"7F800000";
                        result_v(31) := z_sign;
                    elsif a_zero = '1' or b_zero = '1' then
                        result_v(31) := z_sign;
                    else
                        special_case <= '0';
                    end if;

                    special_result <= result_v;

                    ma := a_mantissa;
                    mb := b_mantissa;
                    ea := to_integer(a_exponent);
                    eb := to_integer(b_exponent);

                    -- Normalize subnormal inputs using bounded,
                    -- synthesizable combinational shift networks.
                    for i in 0 to 22 loop
                        if ma(23) = '0' and ma /= 0 then
                            ma := shift_left(ma, 1);
                            ea := ea - 1;
                        end if;

                        if mb(23) = '0' and mb /= 0 then
                            mb := shift_left(mb, 1);
                            eb := eb - 1;
                        end if;
                    end loop;

                    a_mantissa <= ma;
                    b_mantissa <= mb;
                    a_exponent <= to_signed(ea, 10);
                    b_exponent <= to_signed(eb, 10);

                when "010" =>
                    product <= resize(a_mantissa * b_mantissa, 50);
                    z_exponent <= a_exponent + b_exponent;
                    z_sign <= a_sign xor b_sign;

                when "011" =>
                    -- Place the normalized leading bit at product(47).
                    if product(47) = '1' then
                        z_exponent <= z_exponent + to_signed(1, 10);
                    else
                        product <= shift_left(product, 1);
                    end if;

                when "100" =>
                    p := product;

                    -- Gradual underflow: right-shift with jamming before
                    -- extracting guard, round, and sticky bits.
                    if to_integer(z_exponent) < -126 then
                        shift_count := -126 - to_integer(z_exponent);
                        lost_bits := '0';

                        for i in 0 to 49 loop
                            if i < shift_count then
                                lost_bits := lost_bits or p(i);
                            end if;
                        end loop;

                        p := shift_right(p, shift_count);
                        p(0) := p(0) or lost_bits;
                        z_exponent <= to_signed(-126, 10);
                    end if;

                    sticky_v := '0';
                    for i in 0 to 21 loop
                        sticky_v := sticky_v or p(i);
                    end loop;

                    product    <= p;
                    z_mantissa <= p(47 downto 24);
                    guard_bit  <= p(23);
                    round_bit  <= p(22);
                    sticky     <= sticky_v;

                when "101" =>
                    -- IEEE-754 round to nearest, ties to even.
                    rounded := resize(z_mantissa, 25);

                    if guard_bit = '1' and
                       (round_bit = '1' or sticky = '1' or
                        z_mantissa(0) = '1') then
                        rounded := rounded + 1;
                    end if;

                    if rounded(24) = '1' then
                        z_mantissa <= rounded(24 downto 1);
                        z_exponent <= z_exponent + to_signed(1, 10);
                    else
                        z_mantissa <= rounded(23 downto 0);
                    end if;

                when "110" =>
                    result_v := (others => '0');
                    result_v(31) := z_sign;
                    exponent_v := to_integer(z_exponent);

                    if special_case = '1' then
                        result_v := special_result;
                    elsif exponent_v > 127 then
                        result_v(30 downto 23) := x"FF";
                    elsif z_mantissa = 0 then
                        null;
                    elsif exponent_v = -126 and z_mantissa(23) = '0' then
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    else
                        result_v(30 downto 23) :=
                            std_logic_vector(to_unsigned(exponent_v + 127, 8));
                        result_v(22 downto 0) :=
                            std_logic_vector(z_mantissa(22 downto 0));
                    end if;

                    packed_result <= result_v;

                when "111" =>
                    z <= packed_result;

                when others =>
                    counter <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
