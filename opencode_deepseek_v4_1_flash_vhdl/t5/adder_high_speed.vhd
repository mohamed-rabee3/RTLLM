library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_fast is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(16 downto 0)
    );
end entity add_fast;

architecture rtl of add_fast is
    signal low_sum     : std_logic_vector(7 downto 0);
    signal low_carry   : std_logic;
    signal high_sum0   : unsigned(8 downto 0);
    signal high_sum1   : unsigned(8 downto 0);
    signal high_sum_sel: unsigned(8 downto 0);
begin

    process(a, b)
        variable sum9 : unsigned(8 downto 0);
    begin
        sum9 := resize(unsigned(a(7 downto 0)), 9) + resize(unsigned(b(7 downto 0)), 9);
        low_sum   <= std_logic_vector(sum9(7 downto 0));
        low_carry <= sum9(8);
    end process;

    process(a, b)
        variable upper_add : unsigned(8 downto 0);
    begin
        upper_add := resize(unsigned(a(15 downto 8)), 9) + resize(unsigned(b(15 downto 8)), 9);
        high_sum0 <= upper_add;
        high_sum1 <= upper_add + 1;
    end process;

    high_sum_sel <= high_sum1 when low_carry = '1' else high_sum0;

    result <= std_logic_vector(high_sum_sel) & low_sum;

end architecture rtl;
