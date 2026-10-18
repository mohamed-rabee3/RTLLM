library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_interpolator is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(15 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end entity fir_interpolator;

architecture rtl of fir_interpolator is
    constant H0 : signed(15 downto 0) := to_signed(64, 16);
    constant H1 : signed(15 downto 0) := to_signed(128, 16);
    constant H2 : signed(15 downto 0) := to_signed(128, 16);
    constant H3 : signed(15 downto 0) := to_signed(64, 16);

    type delay_array_t is array (0 to 3) of signed(15 downto 0);
    signal delay_line : delay_array_t;

begin
    process (clk)
        variable accumulator : signed(33 downto 0);
        variable scaled      : signed(33 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                delay_line <= (others => (others => '0'));
                valid_out  <= '0';
                data_out   <= (others => '0');
            else
                valid_out <= '0';

                if valid_in = '1' then
                    accumulator :=
                        resize(signed(data_in) * H0, accumulator'length) +
                        resize(delay_line(0) * H1, accumulator'length) +
                        resize(delay_line(1) * H2, accumulator'length) +
                        resize(delay_line(2) * H3, accumulator'length);

                    scaled := shift_right(accumulator, 8);

                    data_out  <= std_logic_vector(scaled(15 downto 0));
                    valid_out <= '1';

                    delay_line(0) <= signed(data_in);
                    delay_line(1) <= delay_line(0);
                    delay_line(2) <= delay_line(1);
                    delay_line(3) <= delay_line(2);
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
