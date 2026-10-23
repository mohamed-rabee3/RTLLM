library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accu is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_in  : in  std_logic;
        valid_out : out std_logic;
        data_out  : out std_logic_vector(9 downto 0)
    );
end entity accu;

architecture rtl of accu is
    signal accumulator : unsigned(9 downto 0);
    signal input_count : unsigned(1 downto 0);
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            accumulator <= (others => '0');
            input_count <= (others => '0');
            data_out    <= (others => '0');
            valid_out   <= '0';
        elsif rising_edge(clk) then
            valid_out <= '0';

            if valid_in = '1' then
                if input_count = to_unsigned(3, input_count'length) then
                    data_out <= std_logic_vector(
                        accumulator + resize(unsigned(data_in), accumulator'length)
                    );
                    valid_out   <= '1';
                    accumulator <= (others => '0');
                    input_count <= (others => '0');
                else
                    accumulator <= accumulator
                                   + resize(unsigned(data_in), accumulator'length);
                    input_count <= input_count + 1;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
