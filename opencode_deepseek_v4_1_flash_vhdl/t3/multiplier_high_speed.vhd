library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_fast is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_fast;

architecture rtl of mul_fast is
    type pp_array is array (0 to 15) of unsigned(31 downto 0);
    signal pp : pp_array;

    type level1_array is array (0 to 7) of unsigned(31 downto 0);
    signal l1 : level1_array;

    type level2_array is array (0 to 3) of unsigned(31 downto 0);
    signal l2 : level2_array;

    type level3_array is array (0 to 1) of unsigned(31 downto 0);
    signal l3 : level3_array;

    signal l4 : unsigned(31 downto 0);
begin

    process(a, b)
        variable tmp : unsigned(31 downto 0);
    begin
        for i in 0 to 15 loop
            tmp := (others => '0');
            if b(i) = '1' then
                tmp(15 + i downto i) := unsigned(a);
            end if;
            pp(i) <= tmp;
        end loop;
    end process;

    l1(0) <= pp(0)  + pp(1);
    l1(1) <= pp(2)  + pp(3);
    l1(2) <= pp(4)  + pp(5);
    l1(3) <= pp(6)  + pp(7);
    l1(4) <= pp(8)  + pp(9);
    l1(5) <= pp(10) + pp(11);
    l1(6) <= pp(12) + pp(13);
    l1(7) <= pp(14) + pp(15);

    l2(0) <= l1(0) + l1(1);
    l2(1) <= l1(2) + l1(3);
    l2(2) <= l1(4) + l1(5);
    l2(3) <= l1(6) + l1(7);

    l3(0) <= l2(0) + l2(1);
    l3(1) <= l2(2) + l2(3);

    l4 <= l3(0) + l3(1);

    result <= std_logic_vector(l4);

end rtl;
