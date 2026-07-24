library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_mul_fast is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(31 downto 0));
end verified_mul_fast;
architecture rtl of verified_mul_fast is
    type pp_t is array (0 to 15) of unsigned(31 downto 0);
begin
    process(a, b)
        variable pp  : pp_t;
        variable acc : unsigned(31 downto 0);
    begin
        for i in 0 to 15 loop
            if b(i) = '1' then
                pp(i) := shift_left(resize(unsigned(a), 32), i);
            else
                pp(i) := (others => '0');
            end if;
        end loop;
        acc := (others => '0');
        for i in 0 to 15 loop
            acc := acc + pp(i);
        end loop;
        result <= std_logic_vector(acc);
    end process;
end rtl;
