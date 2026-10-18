library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sorting_3_numbers is
    Port (
        a1  : in  std_logic_vector(9 downto 0);
        a2  : in  std_logic_vector(9 downto 0);
        a3  : in  std_logic_vector(9 downto 0);
        max : out std_logic_vector(9 downto 0);
        med : out std_logic_vector(9 downto 0);
        min : out std_logic_vector(9 downto 0)
    );
end sorting_3_numbers;

architecture rtl of sorting_3_numbers is
begin

    process(a1, a2, a3)
        variable v1, v2, v3 : unsigned(9 downto 0);
        variable tmp        : unsigned(9 downto 0);
    begin
        v1 := unsigned(a1);
        v2 := unsigned(a2);
        v3 := unsigned(a3);

        if v1 > v2 then
            tmp := v1;
            v1 := v2;
            v2 := tmp;
        end if;

        if v2 > v3 then
            tmp := v2;
            v2 := v3;
            v3 := tmp;
        end if;

        if v1 > v2 then
            tmp := v1;
            v1 := v2;
            v2 := tmp;
        end if;

        max <= std_logic_vector(v3);
        med <= std_logic_vector(v2);
        min <= std_logic_vector(v1);
    end process;

end rtl;
