library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end add;

architecture rtl of add is
    signal sum : unsigned(16 downto 0);
begin
    sum <= resize(unsigned(a), 17) + resize(unsigned(b), 17);
    result <= std_logic_vector(sum);
end rtl;
