library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator_3bit is
    port (
        A         : in  std_logic_vector(2 downto 0);
        B         : in  std_logic_vector(2 downto 0);
        A_greater : out std_logic;
        A_equal   : out std_logic;
        A_less    : out std_logic
    );
end entity comparator_3bit;

architecture behavioral of comparator_3bit is
begin
    process(A, B)
    begin
        -- Compare A and B as unsigned values
        if unsigned(A) > unsigned(B) then
            A_greater <= '1';
            A_equal   <= '0';
            A_less    <= '0';
        elsif unsigned(A) = unsigned(B) then
            A_greater <= '0';
            A_equal   <= '1';
            A_less    <= '0';
        else
            A_greater <= '0';
            A_equal   <= '0';
            A_less    <= '1';
        end if;
    end process;
end architecture behavioral;