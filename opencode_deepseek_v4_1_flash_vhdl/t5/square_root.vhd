library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SQRT is
    Port ( value  : in  std_logic_vector(15 downto 0);
           result : out std_logic_vector(7 downto 0));
end SQRT;

architecture Behavioral of SQRT is
begin
    process(value)
        variable v        : unsigned(15 downto 0);
        variable rem_var  : unsigned(17 downto 0);
        variable root_var : unsigned(7 downto 0);
        variable trial    : unsigned(17 downto 0);
    begin
        v := unsigned(value);
        rem_var  := (others => '0');
        root_var := (others => '0');

        for i in 7 downto 0 loop
            rem_var := shift_left(rem_var, 2) or resize(v(2*i+1 downto 2*i), rem_var'length);
            root_var := shift_left(root_var, 1);
            trial := resize(root_var & '1', rem_var'length);

            if rem_var >= trial then
                rem_var := rem_var - trial;
                root_var := root_var + 1;
            end if;
        end loop;

        result <= std_logic_vector(root_var);
    end process;
end Behavioral;
