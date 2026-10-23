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
    signal a_ext : unsigned(16 downto 0);
    signal b_ext : unsigned(16 downto 0);
    signal sum   : unsigned(16 downto 0);
begin
    a_ext <= '0' & unsigned(a);
    b_ext <= '0' & unsigned(b);
    sum   <= a_ext + b_ext;
    result <= std_logic_vector(sum);
end rtl;
