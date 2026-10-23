library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity parallel2serial is
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        d         : in  STD_LOGIC_VECTOR (3 downto 0);
        valid_out : out STD_LOGIC;
        dout      : out STD_LOGIC
    );
end parallel2serial;

architecture rtl of parallel2serial is
    signal data  : STD_LOGIC_VECTOR(3 downto 0);
    signal cnt   : integer range 0 to 3;
    signal valid : STD_LOGIC;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            data  <= (others => '0');
            cnt   <= 0;
            valid <= '0';
        elsif rising_edge(clk) then
            if cnt = 3 then
                data  <= d;
                cnt   <= 0;
                valid <= '1';
            else
                data  <= data(2 downto 0) & data(3);
                cnt   <= cnt + 1;
                valid <= '0';
            end if;
        end if;
    end process;

    dout      <= data(3);
    valid_out <= valid;
end rtl;
