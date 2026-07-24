library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_add_fast is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(16 downto 0));
end verified_add_fast;
architecture rtl of verified_add_fast is
    signal lo, hi0, hi1, hi : unsigned(8 downto 0);
begin
    lo  <= ('0' & unsigned(a(7 downto 0)))  + ('0' & unsigned(b(7 downto 0)));
    hi0 <= ('0' & unsigned(a(15 downto 8))) + ('0' & unsigned(b(15 downto 8)));
    hi1 <= ('0' & unsigned(a(15 downto 8))) + ('0' & unsigned(b(15 downto 8))) + 1;
    hi  <= hi1 when lo(8) = '1' else hi0;
    result <= std_logic_vector(hi) & std_logic_vector(lo(7 downto 0));
end rtl;
