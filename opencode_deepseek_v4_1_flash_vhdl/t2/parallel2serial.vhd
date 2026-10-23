library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity parallel2serial is
    Port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        d         : in  std_logic_vector(3 downto 0);
        valid_out : out std_logic;
        dout      : out std_logic
    );
end parallel2serial;

architecture Behavioral of parallel2serial is
    signal cnt   : integer range 0 to 3;
    signal data  : std_logic_vector(3 downto 0);
    signal valid : std_logic;
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
                    cnt   <= 0;
                    data  <= d;
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
