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
        variable remainder_v : unsigned(17 downto 0);
        variable trial_v     : unsigned(17 downto 0);
        variable root_v      : unsigned(7 downto 0);
    begin
        remainder_v := (others => '0');
        trial_v     := (others => '0');
        root_v      := (others => '0');

        for i in 7 downto 0 loop
            -- Bring down the next input bit pair, most significant first.
            remainder_v := shift_left(remainder_v, 2);
            remainder_v(1 downto 0) :=
                unsigned(value(2*i + 1 downto 2*i));

            -- Reserve the next root bit and form 4 * previous_root + 1.
            root_v  := shift_left(root_v, 1);
            trial_v := shift_left(resize(root_v, trial_v'length), 1);
            trial_v(0) := '1';

            if remainder_v >= trial_v then
                remainder_v := remainder_v - trial_v;
                root_v(0) := '1';
            end if;
        end loop;

        result <= std_logic_vector(root_v);
    end process;
end architecture rtl;
