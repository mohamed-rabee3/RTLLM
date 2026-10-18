library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQRT is
    Port (
        value  : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (7 downto 0)
    );
end SQRT;

architecture Behavioral of SQRT is
begin
    process(value)
        variable val   : unsigned(15 downto 0);
        variable rem   : unsigned(15 downto 0);
        variable root  : unsigned(7 downto 0);
        variable trial : unsigned(15 downto 0);
    begin
        val := unsigned(value);
        rem := (others => '0');
        root := (others => '0');

        for i in 7 downto 0 loop
            rem := shift_left(rem, 2);
            rem(1 downto 0) := val(2*i+1 downto 2*i);

            trial := shift_left(resize(root, 16), 2) + to_unsigned(1, 16);

            if rem >= trial then
                rem := rem - trial;
                root := shift_left(root, 1);
                root(0) := '1';
            else
                root := shift_left(root, 1);
                root(0) := '0';
            end if;
        end loop;

        result <= std_logic_vector(root);
    end process;
end Behavioral;
