library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider is
    port (
        dividend : in  std_logic_vector(15 downto 0);
        divisor  : in  std_logic_vector(15 downto 0);
        quotient : out std_logic_vector(15 downto 0)
    );
end divider;

architecture Behavioral of divider is
begin
    process(dividend, divisor)
        variable num : signed(23 downto 0);
        variable den : signed(15 downto 0);
        variable q   : signed(23 downto 0);
    begin
        if divisor = "0000000000000000" then
            quotient <= (others => '1');
        else
            num := shift_left(resize(signed(dividend), 24), 7);
            den := signed(divisor);
            q := num / den;
            quotient <= std_logic_vector(resize(q, 16));
        end if;
    end process;
end Behavioral;
