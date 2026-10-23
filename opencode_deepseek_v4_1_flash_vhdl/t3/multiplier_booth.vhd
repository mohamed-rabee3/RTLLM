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
        variable aa  : signed(33 downto 0);
        variable sum : signed(33 downto 0);
        variable pp  : signed(33 downto 0);
        variable enc : std_logic_vector(2 downto 0);
    begin
        aa  := (others => '0');
        aa(15 downto 0) := signed(a);
        sum := (others => '0');

        for i in 0 to 7 loop
            if i = 0 then
                enc := b(1) & b(0) & '0';
            else
                enc := b(2*i+1) & b(2*i) & b(2*i-1);
            end if;

            case enc is
                when "001" | "010" =>
                    pp := aa;
                when "011" =>
                    pp := aa + aa;
                when "100" =>
                    pp := -aa - aa;
                when "101" | "110" =>
                    pp := -aa;
                when others =>
                    pp := (others => '0');
            end case;

            pp  := shift_left(pp, 2*i);
            sum := sum + pp;
        end loop;

        if b(15) = '1' then
            pp  := shift_left(aa, 16);
            sum := sum + pp;
        end if;

        result <= std_logic_vector(sum(31 downto 0));
    end process;
end rtl;
