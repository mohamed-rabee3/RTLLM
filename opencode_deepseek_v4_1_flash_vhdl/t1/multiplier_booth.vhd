library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_booth is
    Port (
        a      : in  STD_LOGIC_VECTOR (15 downto 0);
        b      : in  STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_booth;

architecture rtl of mul_booth is
begin
    process(a, b)
        variable sum_v  : signed(35 downto 0);
        variable a_ext  : signed(35 downto 0);
        variable pp     : signed(35 downto 0);
        variable triple : std_logic_vector(2 downto 0);
    begin
        a_ext := resize(signed('0' & a), 36);
        sum_v := (others => '0');

        for i in 0 to 8 loop
            if i = 0 then
                triple := b(1) & b(0) & '0';
            elsif i = 8 then
                triple := '0' & '0' & b(15);
            else
                triple := b(2*i + 1) & b(2*i) & b(2*i - 1);
            end if;

            case triple is
                when "000" | "111" =>
                    pp := (others => '0');
                when "001" | "010" =>
                    pp := a_ext;
                when "011" =>
                    pp := shift_left(a_ext, 1);
                when "100" =>
                    pp := -shift_left(a_ext, 1);
                when "101" | "110" =>
                    pp := -a_ext;
                when others =>
                    pp := (others => '0');
            end case;

            pp := shift_left(pp, 2*i);
            sum_v := sum_v + pp;
        end loop;

        result <= std_logic_vector(sum_v(31 downto 0));
    end process;
end rtl;
