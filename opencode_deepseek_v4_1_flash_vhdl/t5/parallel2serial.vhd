library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity parallel2serial is
    Port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        d         : in  std_logic_vector(3 downto 0);
        valid_out : out std_logic;
        dout      : out std_logic
    );
end parallel2serial;

architecture rtl of parallel2serial is
    signal cnt  : unsigned(1 downto 0);
    signal data : std_logic_vector(3 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt       <= (others => '0');
            data      <= (others => '0');
            valid_out <= '0';
        elsif rising_edge(clk) then
            if cnt = 3 then
                data      <= d;
                cnt       <= (others => '0');
                valid_out <= '1';
            else
                cnt       <= cnt + 1;
                valid_out <= '0';
                data      <= data(2 downto 0) & data(3);
            end if;
        end if;
    end process;

    dout <= data(3);

end rtl;
