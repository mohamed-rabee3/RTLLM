library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity width_8to16 is
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR (7 downto 0);
        valid_out : out STD_LOGIC;
        data_out  : out STD_LOGIC_VECTOR (15 downto 0)
    );
end width_8to16;

architecture rtl of width_8to16 is
    signal data_lock   : STD_LOGIC_VECTOR(7 downto 0);
    signal flag        : STD_LOGIC;
    signal valid_out_r : STD_LOGIC;
    signal data_out_r  : STD_LOGIC_VECTOR(15 downto 0);
begin
    valid_out <= valid_out_r;
    data_out  <= data_out_r;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data_lock   <= (others => '0');
            flag        <= '0';
            valid_out_r <= '0';
            data_out_r  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out_r <= '0';

            if valid_in = '1' then
                if flag = '0' then
                    data_lock <= data_in;
                    flag      <= '1';
                else
                    data_out_r  <= data_lock & data_in;
                    valid_out_r <= '1';
                    flag        <= '0';
                end if;
            end if;
        end if;
    end process;
end rtl;
