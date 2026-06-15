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
    signal data  : std_logic_vector(3 downto 0);
    signal cnt   : integer range 0 to 3;
    signal valid : std_logic;
begin
    -- Most significant bit of the data register is the serial output
    dout      <= data(3);
    valid_out <= valid;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            data  <= (others => '0');
            cnt   <= 0;
            valid <= '0';
        elsif rising_edge(clk) then
            if cnt = 3 then
                -- Last bit of current word: load new parallel data,
                -- reset counter, and assert valid for the next word.
                data  <= d;
                cnt   <= 0;
                valid <= '1';
            else
                -- Shift left with MSB rotated to LSB
                data  <= data(2 downto 0) & data(3);
                cnt   <= cnt + 1;
                valid <= '0';
            end if;
        end if;
    end process;
end architecture rtl;