library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_8bit is
    Port (
        A       : in  STD_LOGIC_VECTOR (7 downto 0);
        B       : in  STD_LOGIC_VECTOR (7 downto 0);
        product : out STD_LOGIC_VECTOR (15 downto 0)
    );
end multi_8bit;

architecture rtl of multi_8bit is
begin
    process(A, B)
        variable temp         : unsigned(15 downto 0);
        variable multiplicand : unsigned(15 downto 0);
    begin
        temp := (others => '0');
        multiplicand := resize(unsigned(A), 16);

        for i in 0 to 7 loop
            if B(i) = '1' then
                temp := temp + multiplicand;
            end if;
            multiplicand := multiplicand sll 1;
        end loop;

        product <= std_logic_vector(temp);
    end process;
end rtl;
