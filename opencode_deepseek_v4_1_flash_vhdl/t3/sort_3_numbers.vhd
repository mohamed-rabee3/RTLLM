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
    signal u1, u2, u3       : unsigned(9 downto 0);
    signal lo12, hi12       : unsigned(9 downto 0);
    signal max_s, temp_s    : unsigned(9 downto 0);
    signal med_s, min_s     : unsigned(9 downto 0);
begin

    u1 <= unsigned(a1);
    u2 <= unsigned(a2);
    u3 <= unsigned(a3);

    -- Compare and swap a1 and a2
    lo12 <= u1 when u1 < u2 else u2;
    hi12 <= u2 when u1 < u2 else u1;

    -- Compare the larger side with a3
    max_s  <= hi12 when hi12 > u3 else u3;
    temp_s <= u3   when hi12 > u3 else hi12;

    -- Compare and swap the remaining pair
    med_s <= lo12  when lo12 > temp_s else temp_s;
    min_s <= temp_s when lo12 > temp_s else lo12;

    max <= std_logic_vector(max_s);
    med <= std_logic_vector(med_s);
    min <= std_logic_vector(min_s);

end Behavioral;
