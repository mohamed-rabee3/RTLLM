library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider is
    port (
        dividend : in signed(15 downto 0);
        divisor  : in signed(15 downto 0);
        quotient : out signed(15 downto 0)
    );
end entity divider;

architecture rtl of divider is
begin
    process(dividend, divisor)
        variable abs_dividend : unsigned(15 downto 0);
        variable abs_divisor  : unsigned(15 downto 0);
        variable shifted      : unsigned(31 downto 0);
        variable divisor_ext  : unsigned(31 downto 0);
        variable remainder    : unsigned(31 downto 0);
        variable q            : unsigned(31 downto 0);
        variable sign_neg     : std_logic;
        variable result       : signed(31 downto 0);
    begin
        if divisor = 0 then
            quotient <= (others => '1');
        else
            -- Absolute value of dividend
            if dividend < 0 then
                abs_dividend := unsigned(not std_logic_vector(dividend)) + 1;
            else
                abs_dividend := unsigned(std_logic_vector(dividend));
            end if;

            -- Absolute value of divisor
            if divisor < 0 then
                abs_divisor := unsigned(not std_logic_vector(divisor)) + 1;
            else
                abs_divisor := unsigned(std_logic_vector(divisor));
            end if;

            -- Shift dividend left by 7 bits to align to Q8.7
            shifted := shift_left(resize(abs_dividend, 32), 7);
            divisor_ext := resize(abs_divisor, 32);

            -- Unsigned restoring division
            remainder := (others => '0');
            q := (others => '0');
            for i in 31 downto 0 loop
                remainder := shift_left(remainder, 1);
                remainder(0) := shifted(i);
                if remainder >= divisor_ext then
                    remainder := remainder - divisor_ext;
                    q(i) := '1';
                end if;
            end loop;

            -- Apply sign
            sign_neg := dividend(15) xor divisor(15);
            if sign_neg = '1' then
                result := -signed(q);
            else
                result := signed(q);
            end if;

            quotient <= result(15 downto 0);
        end if;
    end process;
end architecture rtl;
