library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parallel2serial is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        d         : in  std_logic_vector(3 downto 0);
        valid_out : out std_logic;
        dout      : out std_logic
    );
end entity parallel2serial;

architecture rtl of parallel2serial is
    signal cnt   : unsigned(1 downto 0);
    signal data  : std_logic_vector(3 downto 0);
    signal valid : std_logic;
begin
    dout      <= data(3);
    valid_out <= valid;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cnt   <= (others => '0');
            data  <= (others => '0');
            valid <= '0';
        elsif rising_edge(clk) then
            if cnt = to_unsigned(3, cnt'length) then
                cnt   <= (others => '0');
                data  <= d;
                valid <= '1';
            else
                cnt   <= cnt + 1;
                data  <= data(2 downto 0) & data(3);
                valid <= '0';
            end if;
        end if;
    end process;
end architecture rtl;
