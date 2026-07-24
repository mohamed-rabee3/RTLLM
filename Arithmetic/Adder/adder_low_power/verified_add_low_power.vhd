library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_add_low_power is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(16 downto 0));
end verified_add_low_power;
architecture rtl of verified_add_low_power is
begin
    result <= std_logic_vector(resize(unsigned(a), 17) + resize(unsigned(b), 17));
end rtl;
