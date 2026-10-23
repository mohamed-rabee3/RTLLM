library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_booth is
    Port ( a      : in  STD_LOGIC_VECTOR (15 downto 0);
           b      : in  STD_LOGIC_VECTOR (15 downto 0);
           result : out STD_LOGIC_VECTOR (31 downto 0));
end mul_booth;

architecture Behavioral of mul_booth is
begin
    process(a, b)
        variable acc    : signed(33 downto 0);
        variable a_ext  : signed(33 downto 0);
        variable pp     : signed(33 downto 0);
        variable b_prev : std_logic;
    begin
        a_ext := resize(signed('0' & a), 34);

        if b(15) = '1' then
            acc := shift_left(a_ext, 16);
        else
            acc := (others => '0');
        end if;

        for i in 0 to 7 loop
            if i = 0 then
                b_prev := '0';
            else
                b_prev := b(2*i - 1);
            end if;

            case (b(2*i+1) & b(2*i) & b_prev) is
                when "000" =>
                    pp := (others => '0');
                when "001" =>
                    pp := a_ext;
                when "010" =>
                    pp := a_ext;
                when "011" =>
                    pp := shift_left(a_ext, 1);
                when "100" =>
                    pp := -shift_left(a_ext, 1);
                when "101" =>
                    pp := -a_ext;
                when "110" =>
                    pp := -a_ext;
                when "111" =>
                    pp := (others => '0');
                when others =>
                    pp := (others => '0');
            end case;

            pp := shift_left(pp, 2*i);
            acc := acc + pp;
        end loop;

        result <= std_logic_vector(acc(31 downto 0));
    end process;
end Behavioral;
