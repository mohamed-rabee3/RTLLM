library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_SQRT is
    port(value : in  std_logic_vector(15 downto 0);
         result : out std_logic_vector(7 downto 0));
end verified_SQRT;
architecture rtl of verified_SQRT is
begin
    process(value)
        variable res   : unsigned(7 downto 0);
        variable rem_v : unsigned(17 downto 0);
        variable trial : unsigned(17 downto 0);
        variable two   : unsigned(1 downto 0);
    begin
        res   := (others => '0');
        rem_v := (others => '0');
        for i in 7 downto 0 loop
            two   := unsigned(value(i*2+1 downto i*2));
            rem_v := (rem_v(15 downto 0) & two);           -- rem << 2 | next two bits
            trial := resize(res & "01", 18);                -- (res<<2) | 1
            if rem_v >= trial then
                rem_v := rem_v - trial;
                res   := res(6 downto 0) & '1';             -- (res<<1) | 1
            else
                res   := res(6 downto 0) & '0';             -- res<<1
            end if;
        end loop;
        result <= std_logic_vector(res);
    end process;
end rtl;
