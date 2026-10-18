library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SQRT is
    port (
        value  : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(7 downto 0)
    );
end entity SQRT;

architecture rtl of SQRT is
begin
    process(value)
        variable partial_root : unsigned(7 downto 0);
        variable remainder_v  : unsigned(17 downto 0);
        variable trial        : unsigned(17 downto 0);
    begin
        partial_root := (others => '0');
        remainder_v  := (others => '0');
        trial        := (others => '0');

        for i in 7 downto 0 loop
            -- Bring down the next pair of radicand bits.
            remainder_v := shift_left(remainder_v, 2);
            remainder_v(1 downto 0) :=
                unsigned(value(2 * i + 1 downto 2 * i));

            -- Append a zero root bit, then form 4 * old_root + 1.
            partial_root := shift_left(partial_root, 1);
            trial := shift_left(resize(partial_root, trial'length), 1);
            trial(0) := '1';

            if remainder_v >= trial then
                remainder_v := remainder_v - trial;
                partial_root(0) := '1';
            end if;
        end loop;

        result <= std_logic_vector(partial_root);
    end process;
end architecture rtl;
