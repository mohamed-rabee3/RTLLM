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
    signal SR          : unsigned(15 downto 0);
    signal NEG_DIVISOR : signed(8 downto 0);
    signal cnt         : unsigned(3 downto 0);
    signal start_cnt   : std_logic;

    signal quotient_negative  : std_logic;
    signal remainder_negative : std_logic;
    signal valid_reg          : std_logic;
    signal result_reg         : std_logic_vector(15 downto 0);
begin
    res_valid <= valid_reg;
    result    <= result_reg;

    process (clk, rst)
        variable dividend_abs : unsigned(7 downto 0);
        variable divisor_abs  : unsigned(7 downto 0);
        variable difference   : signed(8 downto 0);
        variable remainder_v  : unsigned(7 downto 0);
        variable quotient_v   : unsigned(7 downto 0);
        variable quotient_bit : std_logic;
    begin
        if rst = '1' then
            SR                 <= (others => '0');
            NEG_DIVISOR        <= (others => '0');
            cnt                <= (others => '0');
            start_cnt          <= '0';
            quotient_negative  <= '0';
            remainder_negative <= '0';
            valid_reg          <= '0';
            result_reg         <= (others => '0');

        elsif rising_edge(clk) then
            -- With no result-ready input, validity is a one-clock pulse.
            valid_reg <= '0';

            if start_cnt = '1' then
                difference := signed('0' & SR(15 downto 8))
                              + NEG_DIVISOR;

                if difference(8) = '0' then
                    remainder_v  := unsigned(difference(7 downto 0));
                    quotient_bit := '1';
                else
                    remainder_v  := SR(15 downto 8);
                    quotient_bit := '0';
                end if;

                if cnt(3) = '1' then
                    quotient_v := SR(6 downto 0) & quotient_bit;

                    -- The last iteration appends the quotient bit without
                    -- shifting the completed remainder.
                    SR        <= remainder_v & quotient_v;
                    cnt       <= (others => '0');
                    start_cnt <= '0';

                    if quotient_negative = '1' then
                        quotient_v := (not quotient_v) + to_unsigned(1, 8);
                    end if;

                    if remainder_negative = '1' then
                        remainder_v := (not remainder_v) + to_unsigned(1, 8);
                    end if;

                    result_reg <= std_logic_vector(remainder_v)
                                & std_logic_vector(quotient_v);
                    valid_reg <= '1';
                else
                    SR <= remainder_v(6 downto 0)
                          & SR(7 downto 0)
                          & quotient_bit;
                    cnt <= cnt + to_unsigned(1, cnt'length);
                end if;

            elsif opn_valid = '1' and valid_reg = '0' then
                dividend_abs := unsigned(dividend);
                divisor_abs  := unsigned(divisor);

                if sign = '1' and dividend(7) = '1' then
                    dividend_abs := (not unsigned(dividend))
                                    + to_unsigned(1, 8);
                end if;

                if sign = '1' and divisor(7) = '1' then
                    divisor_abs := (not unsigned(divisor))
                                   + to_unsigned(1, 8);
                end if;

                quotient_negative  <= sign and (dividend(7) xor divisor(7));
                remainder_negative <= sign and dividend(7);

                SR <= shift_left(resize(dividend_abs, SR'length), 1);
                NEG_DIVISOR <= -signed('0' & divisor_abs);
                cnt         <= to_unsigned(1, cnt'length);
                start_cnt   <= '1';
            end if;
        end if;
    end process;
end architecture rtl;
