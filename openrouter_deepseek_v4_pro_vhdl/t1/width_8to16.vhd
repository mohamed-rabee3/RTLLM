library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

    signal data_lock : std_logic_vector(7 downto 0);
    signal flag      : std_logic; -- '1' when first byte is stored and waiting for second

begin

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            data_lock <= (others => '0');
            flag      <= '0';
            valid_out <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            -- Default valid_out to '0'; will be overridden if a valid output is generated
            valid_out <= '0';

            if valid_in = '1' then
                if flag = '1' then
                    -- Second byte arrived: concatenate stored byte (high) and new byte (low)
                    data_out  <= data_lock & data_in;
                    valid_out <= '1';
                    flag      <= '0';
                else
                    -- First byte: store it and set flag
                    data_lock <= data_in;
                    flag      <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;