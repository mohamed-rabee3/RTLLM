library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQRT is
    port (
        value  : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(7 downto 0)
    );
end SQRT;

architecture RTL of SQRT is
begin
    process(value)
        variable rad   : unsigned(15 downto 0);
        variable rem   : unsigned(17 downto 0);
        variable root  : unsigned(7 downto 0);
        variable trial : unsigned(17 downto 0);
        variable pair  : unsigned(1 downto 0);
    begin
        rad  := unsigned(value);
        rem  := (others => '0');
        root := (others => '0');

        for i in 0 to 7 loop
            pair := rad(15 downto 14);
            rad  := shift_left(rad, 2);

            rem := shift_left(rem, 2);
            rem(1 downto 0) := pair;

            trial := shift_left(resize(root, rem'length), 2) or
                     to_unsigned(1, rem'length);

            if rem >= trial then
                rem := rem - trial;
                root := shift_left(root, 1);
                root(0) := '1';
            else
                root := shift_left(root, 1);
            end if;
        end loop;

        result <= std_logic_vector(root);
    end process;
end RTL;
