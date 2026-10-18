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
    signal A_ext : unsigned(4 downto 0);
    signal B_ext : unsigned(4 downto 0);
    signal diff  : unsigned(4 downto 0);
begin
    A_ext <= resize(unsigned(A), 5);
    B_ext <= resize(unsigned(B), 5);
    diff  <= A_ext - B_ext;

    A_less    <= diff(4);
    A_equal   <= '1' when diff = "00000" else '0';
    A_greater <= '1' when (diff(4) = '0' and diff(3 downto 0) /= "0000") else '0';
end Behavioral;
