library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQRT is
    Port (
        value  : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(7 downto 0)
    );
end SQRT;

architecture rtl of SQRT is
begin
    process(value)
        variable rem   : unsigned(15 downto 0);
        variable root  : unsigned(7 downto 0);
        variable trial : unsigned(15 downto 0);
    begin
        rem  := (others => '0');
        root := (others => '0');

        for i in 7 downto 0 loop
            rem := shift_left(rem, 2);
            rem(1) := value(2*i + 1);
            rem(0) := value(2*i);

            trial := shift_left(resize(root, trial'length), 2) + to_unsigned(1, trial'length);

            if rem >= trial then
                rem := rem - trial;
                root := shift_left(root, 1) + to_unsigned(1, root'length);
            else
                root := shift_left(root, 1);
            end if;
        end loop;

        result <= std_logic_vector(root);
    end process;
end rtl;
