library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_sorting_3_numbers is
    port(a1, a2, a3 : in  std_logic_vector(9 downto 0);
         max, med, min : out std_logic_vector(9 downto 0));
end verified_sorting_3_numbers;
architecture rtl of verified_sorting_3_numbers is
begin
    process(a1, a2, a3)
        variable x1, x2, x3, t : unsigned(9 downto 0);
    begin
        x1 := unsigned(a1); x2 := unsigned(a2); x3 := unsigned(a3);
        if x1 > x2 then t := x1; x1 := x2; x2 := t; end if;
        if x2 > x3 then t := x2; x2 := x3; x3 := t; end if;
        if x1 > x2 then t := x1; x1 := x2; x2 := t; end if;
        min <= std_logic_vector(x1);
        med <= std_logic_vector(x2);
        max <= std_logic_vector(x3);
    end process;
end rtl;
