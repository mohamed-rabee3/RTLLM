library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_booth is
    Port (
        a : in STD_LOGIC_VECTOR (15 downto 0);
        b : in STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_booth;

architecture rtl of mul_booth is
begin
    process(a, b)
        variable y : std_logic_vector(16 downto 0);
        variable a_s : signed(33 downto 0);
        variable a2_s : signed(33 downto 0);
        variable acc : signed(33 downto 0);
        variable partial : signed(33 downto 0);
        variable bits : std_logic_vector(2 downto 0);
        variable digit : integer range -2 to 2;
    begin
        y := (others => '0');
        y(16 downto 1) := b;

        a_s := resize(signed('0' & a), 34);
        a2_s := shift_left(a_s, 1);
        acc := (others => '0');

        for i in 0 to 7 loop
            bits := y(2*i+2) & y(2*i+1) & y(2*i);
            case bits is
                when "000" | "111" =>
                    digit := 0;
                when "001" | "010" =>
                    digit := 1;
                when "011" =>
                    digit := 2;
                when "100" =>
                    digit := -2;
                when "101" | "110" =>
                    digit := -1;
                when others =>
                    digit := 0;
            end case;

            case digit is
                when 0 =>
                    partial := (others => '0');
                when 1 =>
                    partial := a_s;
                when 2 =>
                    partial := a2_s;
                when -1 =>
                    partial := -a_s;
                when -2 =>
                    partial := -a2_s;
                when others =>
                    partial := (others => '0');
            end case;

            partial := shift_left(partial, 2*i);
            acc := acc + partial;
        end loop;

        if b(15) = '1' then
            acc := acc + shift_left(a_s, 16);
        end if;

        result <= std_logic_vector(resize(acc, 32));
    end process;
end rtl;
