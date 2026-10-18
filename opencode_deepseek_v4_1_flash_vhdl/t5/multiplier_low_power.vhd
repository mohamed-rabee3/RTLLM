library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_low_power is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_low_power;

architecture rtl of mul_low_power is
begin
    process(a, b)
        variable product : unsigned(31 downto 0);
        variable partial : unsigned(31 downto 0);
    begin
        product := (others => '0');
        for i in 0 to 15 loop
            if b(i) = '1' then
                partial := (others => '0');
                for j in 0 to 15 loop
                    partial(i + j) := a(j);
                end loop;
                product := product + partial;
            end if;
        end loop;
        result <= std_logic_vector(product);
    end process;
end rtl;
