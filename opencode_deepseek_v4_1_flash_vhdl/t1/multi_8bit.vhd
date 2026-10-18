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

architecture Behavioral of multi_8bit is
begin
    process(A, B)
        variable product_temp : unsigned(15 downto 0);
        variable shifted_A    : unsigned(15 downto 0);
    begin
        product_temp := (others => '0');
        shifted_A := (others => '0');
        shifted_A(7 downto 0) := unsigned(A);

        for i in 0 to 7 loop
            if B(i) = '1' then
                product_temp := product_temp + shifted_A;
            end if;
            shifted_A := shift_left(shifted_A, 1);
        end loop;

        product <= std_logic_vector(product_temp);
    end process;
end Behavioral;
