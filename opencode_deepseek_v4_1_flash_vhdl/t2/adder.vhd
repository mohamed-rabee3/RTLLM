library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(16 downto 0)
    );
end add;

architecture rtl of add is
begin
    result <= std_logic_vector(resize(unsigned(a), 17) + resize(unsigned(b), 17));
end rtl;
