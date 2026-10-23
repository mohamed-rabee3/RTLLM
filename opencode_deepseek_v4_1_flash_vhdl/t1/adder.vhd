library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add;

architecture rtl of add is
begin
    result <= std_logic_vector(('0' & unsigned(a)) + ('0' & unsigned(b)));
end architecture rtl;
