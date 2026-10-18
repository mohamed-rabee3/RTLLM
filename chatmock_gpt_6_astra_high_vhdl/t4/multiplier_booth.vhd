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
        variable a_ext   : signed(33 downto 0);
        variable b_ext   : std_logic_vector(18 downto 0);
        variable partial : signed(33 downto 0);
        variable accum   : signed(33 downto 0);
        variable booth   : std_logic_vector(2 downto 0);
    begin
        a_ext := signed(resize(unsigned(a), a_ext'length));
        b_ext := "00" & b & '0';
        accum := (others => '0');

        -- Eight radix-4 Booth groups for the 16 multiplier bits.
        for i in 0 to 7 loop
            booth := b_ext(2*i + 2 downto 2*i);

            case booth is
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

            accum := accum + shift_left(partial, 2*i);
        end loop;

        -- Account for the zero extension above the unsigned multiplier.
        -- Without this correction, the eight groups treat b as signed.
        if b_ext(16) = '1' then
            accum := accum + shift_left(a_ext, 16);
        end if;

        result <= std_logic_vector(accum(31 downto 0));
    end process;
end architecture rtl;
