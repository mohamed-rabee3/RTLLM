library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity width_8to16 is
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        valid_out : out STD_LOGIC;
        data_out  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end width_8to16;

architecture rtl of width_8to16 is
    signal data_lock    : STD_LOGIC_VECTOR(7 downto 0);
    signal flag         : STD_LOGIC;
    signal data_out_reg : STD_LOGIC_VECTOR(15 downto 0);
    signal valid_out_reg: STD_LOGIC;
begin
    data_out  <= data_out_reg;
    valid_out <= valid_out_reg;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_lock     <= (others => '0');
            flag          <= '0';
            data_out_reg  <= (others => '0');
            valid_out_reg <= '0';
        elsif rising_edge(clk) then
            if valid_in = '1' then
                if flag = '0' then
                    data_lock     <= data_in;
                    flag          <= '1';
                    valid_out_reg <= '0';
                else
                    data_out_reg  <= data_lock & data_in;
                    flag          <= '0';
                    valid_out_reg <= '1';
                end if;
            else
                valid_out_reg <= '0';
            end if;
        end if;
    end process;
end rtl;
