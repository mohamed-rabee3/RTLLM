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
        variable low_v  : unsigned(9 downto 0);
        variable mid_v  : unsigned(9 downto 0);
        variable high_v : unsigned(9 downto 0);
        variable temp_v : unsigned(9 downto 0);
    begin
        low_v  := unsigned(a1);
        mid_v  := unsigned(a2);
        high_v := unsigned(a3);

        if low_v > mid_v then
            temp_v := low_v;
            low_v  := mid_v;
            mid_v  := temp_v;
        end if;

        if mid_v > high_v then
            temp_v := mid_v;
            mid_v  := high_v;
            high_v := temp_v;
        end if;

        if low_v > mid_v then
            temp_v := low_v;
            low_v  := mid_v;
            mid_v  := temp_v;
        end if;

        min <= std_logic_vector(low_v);
        med <= std_logic_vector(mid_v);
        max <= std_logic_vector(high_v);
    end process;
end architecture rtl;
