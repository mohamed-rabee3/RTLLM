library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_low_area is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul_low_area;

architecture rtl of mul_low_area is
begin
    process(a, b)
        variable sum     : unsigned(31 downto 0);
        variable shifted : unsigned(31 downto 0);
    begin
        sum     := (others => '0');
        shifted := resize(unsigned(a), 32);

        for i in 0 to 15 loop
            if b(i) = '1' then
                sum := sum + shifted;
            end if;
            shifted := shift_left(shifted, 1);
        end loop;

        result <= std_logic_vector(sum);
    end process;
end architecture rtl;
