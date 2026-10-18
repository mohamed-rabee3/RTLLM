library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQRT is
    Port (
        value  : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(7 downto 0)
    );
end SQRT;

architecture Behavioral of SQRT is
begin
    process(value)
        variable v     : unsigned(15 downto 0);
        variable rem   : unsigned(17 downto 0);
        variable root  : unsigned(15 downto 0);
        variable trial : unsigned(17 downto 0);
    begin
        v := unsigned(value);
        rem := (others => '0');
        root := (others => '0');

        for i in 0 to 7 loop
            rem := shift_left(rem, 2) or resize(v(15 downto 14), rem'length);
            v := shift_left(v, 2);

            trial := resize(shift_left(root, 2), rem'length) + to_unsigned(1, rem'length);

            if rem >= trial then
                rem := rem - trial;
                root := shift_left(root, 1);
                root(0) := '1';
            else
                root := shift_left(root, 1);
            end if;
        end loop;

        result <= std_logic_vector(root(7 downto 0));
    end process;
end Behavioral;
