library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0)
    );
end mul;

architecture rtl of mul is
begin
    result <= std_logic_vector(unsigned(a) * unsigned(b));
end rtl;
