library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_booth is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul_booth;

architecture rtl of mul_booth is
begin
    process(a, b)
        variable a_ext       : signed(33 downto 0);
        variable b_ext       : std_logic_vector(18 downto 0);
        variable partial     : signed(33 downto 0);
        variable accumulator : signed(33 downto 0);
        variable booth_bits  : std_logic_vector(2 downto 0);
    begin
        -- Zero-extend both unsigned operands; append the Booth overlap bit.
        a_ext := signed(resize(unsigned(a), a_ext'length));
        b_ext := "00" & b & '0';
        accumulator := (others => '0');

        -- Eight radix-4 Booth partial products cover the sixteen input bits.
        for i in 0 to 7 loop
            booth_bits := b_ext(2*i + 2 downto 2*i);

            case booth_bits is
                when "000" | "111" =>
                    partial := (others => '0');
                when "001" | "010" =>
                    partial := a_ext;
                when "011" =>
                    partial := shift_left(a_ext, 1);
                when "100" =>
                    partial := -shift_left(a_ext, 1);
                when "101" | "110" =>
                    partial := -a_ext;
                when others =>
                    partial := (others => '0');
            end case;

            accumulator := accumulator + shift_left(partial, 2*i);
        end loop;

        -- The eight groups interpret bit 15 as a sign bit. The leading
        -- zero-extension group contributes this unsigned correction.
        if b_ext(16) = '1' then
            accumulator := accumulator + shift_left(a_ext, 16);
        end if;

        result <= std_logic_vector(accumulator(31 downto 0));
    end process;
end architecture rtl;
