library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sorting_3_numbers is
    Port (
        a1  : in  STD_LOGIC_VECTOR(9 downto 0);
        a2  : in  STD_LOGIC_VECTOR(9 downto 0);
        a3  : in  STD_LOGIC_VECTOR(9 downto 0);
        max : out STD_LOGIC_VECTOR(9 downto 0);
        med : out STD_LOGIC_VECTOR(9 downto 0);
        min : out STD_LOGIC_VECTOR(9 downto 0)
    );
end sorting_3_numbers;

architecture Behavioral of sorting_3_numbers is
    signal x, y : unsigned(9 downto 0);
    signal p, q : unsigned(9 downto 0);
begin

    -- Stage 1: compare a1 and a2, x = larger, y = smaller
    process(a1, a2)
    begin
        if unsigned(a1) > unsigned(a2) then
            x <= unsigned(a1);
            y <= unsigned(a2);
        else
            x <= unsigned(a2);
            y <= unsigned(a1);
        end if;
    end process;

    -- Stage 2: compare x (larger of a1,a2) with a3
    process(x, a3)
    begin
        if x > unsigned(a3) then
            p <= x;
            q <= unsigned(a3);
        else
            p <= unsigned(a3);
            q <= x;
        end if;
    end process;

    -- Stage 3: order q and y for med and min, p is max
    process(p, q, y)
    begin
        max <= std_logic_vector(p);
        if q > y then
            med <= std_logic_vector(q);
            min <= std_logic_vector(y);
        else
            med <= std_logic_vector(y);
            min <= std_logic_vector(q);
        end if;
    end process;

end Behavioral;
