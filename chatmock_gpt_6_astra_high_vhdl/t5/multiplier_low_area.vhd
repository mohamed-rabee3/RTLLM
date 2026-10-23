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
        variable running_sum : unsigned(31 downto 0);
        variable shifted_a   : unsigned(31 downto 0);
    begin
        running_sum := (others => '0');
        shifted_a   := resize(unsigned(a), 32);

        for i in 0 to 15 loop
            if b(i) = '1' then
                running_sum := running_sum + shifted_a;
            end if;
            shifted_a := shift_left(shifted_a, 1);
        end loop;

        result <= std_logic_vector(running_sum);
    end process;
end architecture rtl;
