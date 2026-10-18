library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_low_power is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(16 downto 0)
    );
end add_low_power;

architecture rtl of add_low_power is
begin
    result <= std_logic_vector(unsigned('0' & a) + unsigned('0' & b));
end rtl;
