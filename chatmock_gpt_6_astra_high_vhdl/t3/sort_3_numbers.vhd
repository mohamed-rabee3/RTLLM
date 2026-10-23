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
    process (a1, a2, a3)
        variable low_value  : unsigned(9 downto 0);
        variable mid_value  : unsigned(9 downto 0);
        variable high_value : unsigned(9 downto 0);
        variable swap_value : unsigned(9 downto 0);
    begin
        low_value  := unsigned(a1);
        mid_value  := unsigned(a2);
        high_value := unsigned(a3);

        -- Order the first pair.
        if low_value > mid_value then
            swap_value := low_value;
            low_value  := mid_value;
            mid_value  := swap_value;
        end if;

        -- Compare the larger of the first pair with the third input.
        if mid_value > high_value then
            swap_value := mid_value;
            mid_value  := high_value;
            high_value := swap_value;
        end if;

        -- Order the remaining pair.
        if low_value > mid_value then
            swap_value := low_value;
            low_value  := mid_value;
            mid_value  := swap_value;
        end if;

        min <= std_logic_vector(low_value);
        med <= std_logic_vector(mid_value);
        max <= std_logic_vector(high_value);
    end process;
end architecture rtl;
