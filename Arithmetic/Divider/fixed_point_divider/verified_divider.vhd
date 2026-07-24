library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_divider is
    port(dividend : in  std_logic_vector(15 downto 0);
         divisor  : in  std_logic_vector(15 downto 0);
         quotient : out std_logic_vector(15 downto 0));
end verified_divider;
architecture rtl of verified_divider is
begin
    process(dividend, divisor)
        variable num : signed(31 downto 0);
        variable q   : signed(31 downto 0);
    begin
        if signed(divisor) = to_signed(0, 16) then
            quotient <= x"FFFF";
        else
            num := resize(signed(dividend), 32) sll 7;      -- x128, Q8.7 alignment
            q   := num / resize(signed(divisor), 32);        -- signed division, trunc toward zero
            quotient <= std_logic_vector(resize(q, 16));
        end if;
    end process;
end rtl;
