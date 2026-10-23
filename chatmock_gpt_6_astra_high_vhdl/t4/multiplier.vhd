library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul;

architecture rtl of mul is
begin
    result <= std_logic_vector(unsigned(a) * unsigned(b));
end architecture rtl;
