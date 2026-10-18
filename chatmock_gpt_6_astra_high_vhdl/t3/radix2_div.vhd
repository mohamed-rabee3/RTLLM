library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity radix2_div is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        sign      : in  std_logic;
        dividend  : in  std_logic_vector(7 downto 0);
        divisor   : in  std_logic_vector(7 downto 0);
        opn_valid : in  std_logic;
        res_valid : out std_logic;
        result    : out std_logic_vector(15 downto 0)
    );
end entity radix2_div;

architecture rtl of radix2_div is
    signal SR              : unsigned(15 downto 0);
    signal NEG_DIVISOR     : unsigned(8 downto 0);
    signal cnt             : unsigned(3 downto 0);
    signal start_cnt       : std_logic;

    signal saved_dividend  : std_logic_vector(7 downto 0);
    signal saved_divisor   : std_logic_vector(7 downto 0);
    signal saved_sign      : std_logic;

    signal res_valid_reg   : std_logic;
    signal result_reg      : std_logic_vector(15 downto 0);
begin
    res_valid <= res_valid_reg;
    result    <= result_reg;

    process (clk, rst)
        variable dividend_mag : unsigned(7 downto 0);
        variable divisor_mag  : unsigned(7 downto 0);
        variable subtract_sum : unsigned(8 downto 0);
        variable remainder_v  : unsigned(7 downto 0);
        variable quotient_v   : unsigned(7 downto 0);
        variable quotient_bit : std_logic;
    begin
        if rst = '1' then
            SR             <= (others => '0');
            NEG_DIVISOR    <= (others => '0');
            cnt            <= (others => '0');
            start_cnt      <= '0';
            saved_dividend <= (others => '0');
            saved_divisor  <= (others => '0');
            saved_sign     <= '0';
            res_valid_reg  <= '0';
            result_reg     <= (others => '0');

        elsif rising_edge(clk) then
            -- Completion is indicated by a one-clock result-valid pulse.
            res_valid_reg <= '0';

            if start_cnt = '1' then
                -- NEG_DIVISOR equals 256 minus the divisor magnitude.
                -- Bit 8 is therefore the no-borrow bit of the subtraction.
                subtract_sum := resize(SR(15 downto 8), 9)
                                + NEG_DIVISOR;
                quotient_bit := subtract_sum(8);

                if quotient_bit = '1' then
                    remainder_v := subtract_sum(7 downto 0);
                else
                    remainder_v := SR(15 downto 8);
                end if;

                quotient_v := SR(6 downto 0) & quotient_bit;

                if cnt(3) = '1' then
                    -- The last iteration does not shift the remainder.
                    SR        <= remainder_v & quotient_v;
                    cnt       <= (others => '0');
                    start_cnt <= '0';

                    -- Signed division truncates toward zero. The remainder
                    -- has the sign of the original dividend.
                    if saved_sign = '1' then
                        if (saved_dividend(7) xor saved_divisor(7)) = '1' then
                            quotient_v := (not quotient_v)
                                          + to_unsigned(1, 8);
                        end if;

                        if saved_dividend(7) = '1' then
                            remainder_v := (not remainder_v)
                                           + to_unsigned(1, 8);
                        end if;
                    end if;

                    result_reg    <= std_logic_vector(remainder_v)
                                     & std_logic_vector(quotient_v);
                    res_valid_reg <= '1';
                else
                    SR <= remainder_v(6 downto 0)
                          & SR(7 downto 0)
                          & quotient_bit;
                    cnt <= cnt + to_unsigned(1, cnt'length);
                end if;

            elsif opn_valid = '1' and res_valid_reg = '0' then
                saved_dividend <= dividend;
                saved_divisor  <= divisor;
                saved_sign     <= sign;

                dividend_mag := unsigned(dividend);
                divisor_mag  := unsigned(divisor);

                if sign = '1' then
                    if dividend(7) = '1' then
                        dividend_mag := (not dividend_mag)
                                        + to_unsigned(1, 8);
                    end if;

                    if divisor(7) = '1' then
                        divisor_mag := (not divisor_mag)
                                       + to_unsigned(1, 8);
                    end if;
                end if;

                SR <= shift_left(resize(dividend_mag, SR'length), 1);
                NEG_DIVISOR <= to_unsigned(256, NEG_DIVISOR'length)
                               - resize(divisor_mag, NEG_DIVISOR'length);
                cnt       <= to_unsigned(1, cnt'length);
                start_cnt <= '1';
            end if;
        end if;
    end process;
end architecture rtl;
