library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator_3bit is
    port (
        A         : in  STD_LOGIC_VECTOR(2 downto 0);
        B         : in  STD_LOGIC_VECTOR(2 downto 0);
        A_greater : out STD_LOGIC;
        A_equal   : out STD_LOGIC;
        A_less    : out STD_LOGIC
    );
end entity comparator_3bit;

architecture rtl of comparator_3bit is
begin
    A_greater <= '1' when unsigned(A) > unsigned(B) else '0';
    A_equal   <= '1' when unsigned(A) = unsigned(B) else '0';
    A_less    <= '1' when unsigned(A) < unsigned(B) else '0';
end architecture rtl;
