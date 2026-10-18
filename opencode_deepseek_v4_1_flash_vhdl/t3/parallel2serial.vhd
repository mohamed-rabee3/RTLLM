library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity parallel2serial is
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        d         : in  STD_LOGIC_VECTOR(3 downto 0);
        valid_out : out STD_LOGIC;
        dout      : out STD_LOGIC
    );
end parallel2serial;

architecture Behavioral of parallel2serial is
    signal data  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal cnt   : integer range 0 to 3 := 0;
    signal valid : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt   <= 0;
                data  <= (others => '0');
                valid <= '0';
            else
                if cnt = 3 then
                    data  <= d;
                    cnt   <= 0;
                    valid <= '1';
                else
                    cnt   <= cnt + 1;
                    valid <= '0';
                    data  <= data(2 downto 0) & data(3);
                end if;
            end if;
        end if;
    end process;

    dout      <= data(3);
    valid_out <= valid;
end Behavioral;
