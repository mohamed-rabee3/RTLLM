library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator_4bit is
    Port (
        A         : in  STD_LOGIC_VECTOR (3 downto 0);
        B         : in  STD_LOGIC_VECTOR (3 downto 0);
        A_greater : out STD_LOGIC;
        A_equal   : out STD_LOGIC;
        A_less    : out STD_LOGIC
    );
end comparator_4bit;

architecture Behavioral of comparator_4bit is
begin
    process(A, B)
        variable diff : unsigned(4 downto 0);
    begin
        diff := ('0' & unsigned(A)) - ('0' & unsigned(B));

        if diff(4) = '1' then
            A_greater <= '0';
            A_equal   <= '0';
            A_less    <= '1';
        elsif diff(3 downto 0) = "0000" then
            A_greater <= '0';
            A_equal   <= '1';
            A_less    <= '0';
        else
            A_greater <= '1';
            A_equal   <= '0';
            A_less    <= '0';
        end if;
    end process;
end Behavioral;
