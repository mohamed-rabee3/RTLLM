library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity width_8to16 is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end width_8to16;

architecture rtl of width_8to16 is
    signal data_lock    : std_logic_vector(7 downto 0);
    signal flag         : std_logic;
    signal valid_out_reg : std_logic;
    signal data_out_reg  : std_logic_vector(15 downto 0);
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_lock     <= (others => '0');
            flag          <= '0';
            valid_out_reg <= '0';
            data_out_reg  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out_reg <= '0';

            if valid_in = '1' then
                if flag = '1' then
                    data_out_reg  <= data_lock & data_in;
                    valid_out_reg <= '1';
                    flag          <= '0';
                else
                    data_lock <= data_in;
                    flag      <= '1';
                end if;
            end if;
        end if;
    end process;

    valid_out <= valid_out_reg;
    data_out  <= data_out_reg;
end rtl;
