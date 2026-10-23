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
    signal sum_reg   : unsigned(9 downto 0);
    signal count_reg : unsigned(1 downto 0);
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            sum_reg   <= (others => '0');
            count_reg <= (others => '0');
            valid_out <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out <= '0';

            if valid_in = '1' then
                if count_reg = "11" then
                    data_out  <= std_logic_vector(
                        sum_reg + resize(unsigned(data_in), sum_reg'length)
                    );
                    valid_out <= '1';
                    sum_reg   <= (others => '0');
                    count_reg <= (others => '0');
                else
                    sum_reg <= sum_reg
                               + resize(unsigned(data_in), sum_reg'length);
                    count_reg <= count_reg + 1;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
