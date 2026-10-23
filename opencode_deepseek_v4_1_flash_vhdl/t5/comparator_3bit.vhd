library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity comparator_3bit is
    Port (
        A         : in  STD_LOGIC_VECTOR (2 downto 0);
        B         : in  STD_LOGIC_VECTOR (2 downto 0);
        A_greater : out STD_LOGIC;
        A_equal   : out STD_LOGIC;
        A_less    : out STD_LOGIC
    );
end comparator_3bit;

architecture Behavioral of comparator_3bit is
begin

    process(A, B)
    begin
        if A > B then
            A_greater <= '1';
            A_equal   <= '0';
            A_less    <= '0';
        elsif A = B then
            A_greater <= '0';
            A_equal   <= '1';
            A_less    <= '0';
        else
            A_greater <= '0';
            A_equal   <= '0';
            A_less    <= '1';
        end if;
    end process;

end Behavioral;
