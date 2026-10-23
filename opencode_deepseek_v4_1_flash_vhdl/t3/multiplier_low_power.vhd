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
        variable a_ext : unsigned(31 downto 0);
        variable acc   : unsigned(31 downto 0);
    begin
        a_ext := resize(unsigned(a), 32);
        acc   := (others => '0');

        for i in 0 to 15 loop
            if b(i) = '1' then
                acc := acc + (a_ext sll i);
            end if;
        end loop;

        result <= std_logic_vector(acc);
    end process;
end Behavioral;
