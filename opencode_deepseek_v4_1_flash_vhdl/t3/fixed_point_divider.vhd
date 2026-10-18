library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider is
    port (
        dividend : in signed(15 downto 0);
        divisor  : in signed(15 downto 0);
        quotient : out signed(15 downto 0)
    );
end divider;

architecture rtl of divider is
begin
    process(dividend, divisor)
        variable dividend_abs_s : signed(16 downto 0);
        variable divisor_abs_s  : signed(16 downto 0);
        variable dividend_abs   : unsigned(16 downto 0);
        variable divisor_abs    : unsigned(16 downto 0);
        variable divisor_ext    : unsigned(23 downto 0);
        variable numerator      : unsigned(22 downto 0);
        variable remainder      : unsigned(23 downto 0);
        variable q_mag          : unsigned(22 downto 0);
        variable sign           : std_logic;
        variable q_signed       : signed(23 downto 0);
    begin
        if divisor = 0 then
            quotient <= (others => '1');
        else
            -- Absolute value of dividend
            if dividend < 0 then
                dividend_abs_s := -resize(dividend, 17);
            else
                dividend_abs_s := resize(dividend, 17);
            end if;
            dividend_abs := unsigned(dividend_abs_s);

            -- Absolute value of divisor
            if divisor < 0 then
                divisor_abs_s := -resize(divisor, 17);
            else
                divisor_abs_s := resize(divisor, 17);
            end if;
            divisor_abs := unsigned(divisor_abs_s);
            divisor_ext := resize(divisor_abs, 24);

            -- Shift dividend left by 7 bits (multiply by 128)
            numerator := shift_left(resize(dividend_abs, 23), 7);

            -- Unsigned restoring division
            remainder := (others => '0');
            q_mag := (others => '0');
            for i in 22 downto 0 loop
                remainder := shift_left(remainder, 1);
                remainder(0) := numerator(i);
                if remainder >= divisor_ext then
                    remainder := remainder - divisor_ext;
                    q_mag(i) := '1';
                else
                    q_mag(i) := '0';
                end if;
            end loop;

            -- Apply sign
            sign := dividend(15) xor divisor(15);
            if sign = '1' then
                q_signed := -signed(resize(q_mag, 24));
            else
                q_signed := signed(resize(q_mag, 24));
            end if;

            quotient <= resize(q_signed, 16);
        end if;
    end process;
end rtl;
