library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add;

architecture rtl of add is
begin
    result <= std_logic_vector(resize(unsigned(a), 17) +
                               resize(unsigned(b), 17));
end architecture rtl;
