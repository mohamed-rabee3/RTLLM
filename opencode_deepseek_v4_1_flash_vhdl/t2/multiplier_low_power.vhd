library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_low_power is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0)
    );
end mul_low_power;

architecture Behavioral of mul_low_power is
begin
    process(a, b)
        variable prod : unsigned(31 downto 0);
        variable pp   : unsigned(31 downto 0);
    begin
        prod := (others => '0');

        for i in 0 to 15 loop
            if b(i) = '1' then
                pp := resize(unsigned(a), 32);
                pp := shift_left(pp, i);
                prod := prod + pp;
            end if;
        end loop;

        result <= std_logic_vector(prod);
    end process;
end Behavioral;
