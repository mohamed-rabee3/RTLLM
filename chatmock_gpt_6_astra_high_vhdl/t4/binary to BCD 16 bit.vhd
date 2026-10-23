library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2bcd_array is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        binary_in : in  std_logic_vector(15 downto 0);
        bcd_out   : out std_logic_vector(19 downto 0);
        valid_out : out std_logic
    );
end entity bin2bcd_array;

architecture rtl of bin2bcd_array is
begin
    process (clk)
        variable bcd : unsigned(19 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_out   <= (others => '0');
                valid_out <= '0';
            else
                valid_out <= valid_in;

                if valid_in = '1' then
                    bcd := (others => '0');

                    for bit_index in 15 downto 0 loop
                        for digit_index in 0 to 4 loop
                            if bcd(4 * digit_index + 3 downto 4 * digit_index)
                               >= to_unsigned(5, 4) then
                                bcd(4 * digit_index + 3 downto 4 * digit_index) :=
                                    bcd(4 * digit_index + 3 downto 4 * digit_index)
                                    + to_unsigned(3, 4);
                            end if;
                        end loop;

                        bcd := bcd(18 downto 0) & binary_in(bit_index);
                    end loop;

                    bcd_out <= std_logic_vector(bcd);
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
