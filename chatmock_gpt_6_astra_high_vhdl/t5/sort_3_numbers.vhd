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
        variable x    : unsigned(9 downto 0);
        variable y    : unsigned(9 downto 0);
        variable z    : unsigned(9 downto 0);
        variable temp : unsigned(9 downto 0);
    begin
        x := unsigned(a1);
        y := unsigned(a2);
        z := unsigned(a3);

        -- Order the first two inputs.
        if x > y then
            temp := x;
            x := y;
            y := temp;
        end if;

        -- Order the larger side against the third input.
        if y > z then
            temp := y;
            y := z;
            z := temp;
        end if;

        -- Order the remaining pair.
        if x > y then
            temp := x;
            x := y;
            y := temp;
        end if;

        min <= std_logic_vector(x);
        med <= std_logic_vector(y);
        max <= std_logic_vector(z);
    end process;
end architecture rtl;
