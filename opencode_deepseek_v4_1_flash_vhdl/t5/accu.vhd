library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accu is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_in  : in  std_logic;
        valid_out : out std_logic;
        data_out  : out std_logic_vector(9 downto 0)
    );
end accu;

architecture rtl of accu is
    signal count   : unsigned(1 downto 0);
    signal sum_reg : unsigned(9 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            count     <= (others => '0');
            sum_reg   <= (others => '0');
            data_out  <= (others => '0');
            valid_out <= '0';
        elsif rising_edge(clk) then
            valid_out <= '0';

            if valid_in = '1' then
                if count = 3 then
                    data_out  <= std_logic_vector(sum_reg + resize(unsigned(data_in), 10));
                    valid_out <= '1';
                    count     <= (others => '0');
                    sum_reg   <= (others => '0');
                else
                    sum_reg <= sum_reg + resize(unsigned(data_in), 10);
                    count   <= count + 1;
                end if;
            end if;
        end if;
    end process;

end rtl;
