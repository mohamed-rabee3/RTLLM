library ieee;
use ieee.std_logic_1164.all;

entity width_8to16 is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end entity width_8to16;

architecture rtl of width_8to16 is
    signal flag      : std_logic;
    signal data_lock : std_logic_vector(7 downto 0);
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            flag      <= '0';
            data_lock <= (others => '0');
            valid_out <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out <= '0';

            if valid_in = '1' then
                if flag = '0' then
                    data_lock <= data_in;
                    flag      <= '1';
                else
                    data_out  <= data_lock & data_in;
                    valid_out <= '1';
                    flag      <= '0';
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
