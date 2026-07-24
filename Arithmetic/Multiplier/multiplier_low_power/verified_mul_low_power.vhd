library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_mul_low_power is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(31 downto 0));
end verified_mul_low_power;
architecture rtl of verified_mul_low_power is
begin
    result <= std_logic_vector(unsigned(a) * unsigned(b));
end rtl;
