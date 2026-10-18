library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sorting_3_numbers is
    port (
        a1  : in  std_logic_vector(9 downto 0);
        a2  : in  std_logic_vector(9 downto 0);
        a3  : in  std_logic_vector(9 downto 0);
        max : out std_logic_vector(9 downto 0);
        med : out std_logic_vector(9 downto 0);
        min : out std_logic_vector(9 downto 0)
    );
end entity sorting_3_numbers;

architecture rtl of sorting_3_numbers is
begin
    process(a1, a2, a3)
        variable v1, v2, v3 : unsigned(9 downto 0);
        variable t1, t2     : unsigned(9 downto 0);
        variable t3, t4     : unsigned(9 downto 0);
    begin
        v1 := unsigned(a1);
        v2 := unsigned(a2);
        v3 := unsigned(a3);

        -- Stage 1: compare and swap a1 and a2
        if v1 > v2 then
            t1 := v2;
            t2 := v1;
        else
            t1 := v1;
            t2 := v2;
        end if;

        -- Stage 2: compare and swap the larger of (a1, a2) with a3
        if t2 > v3 then
            t3 := v3;
            t4 := t2;
        else
            t3 := t2;
            t4 := v3;
        end if;

        -- Stage 3: compare and swap the remaining pair
        if t1 > t3 then
            min <= std_logic_vector(t3);
            med <= std_logic_vector(t1);
        else
            min <= std_logic_vector(t1);
            med <= std_logic_vector(t3);
        end if;

        max <= std_logic_vector(t4);
    end process;
end architecture rtl;
