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
        variable b_ext       : std_logic_vector(17 downto 0);
        variable booth_bits  : std_logic_vector(2 downto 0);
        variable partial     : signed(33 downto 0);
        variable accumulator : signed(33 downto 0);
    begin
        -- Zero-extend A; zero-extend B and append its implicit previous bit.
        a_ext := signed(resize(unsigned(a), a_ext'length));
        b_ext := '0' & b & '0';
        accumulator := (others => '0');

        -- Eight radix-4 Booth partial products.
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

        -- The eight groups interpret B's MSB as a sign bit.
        -- This correction supplies the zero-extension Booth group,
        -- converting that signed interpretation into an unsigned product.
        if b_ext(16) = '1' then
            accumulator := accumulator + shift_left(a_ext, 16);
        end if;

        result <= std_logic_vector(accumulator(31 downto 0));
    end process;
end architecture rtl;
