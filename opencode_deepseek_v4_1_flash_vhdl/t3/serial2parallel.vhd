library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial2parallel is
    Port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        din_serial     : in  std_logic;
        din_valid      : in  std_logic;
        dout_parallel  : out std_logic_vector(7 downto 0);
        dout_valid     : out std_logic
    );
end serial2parallel;

architecture rtl of serial2parallel is
    signal cnt           : unsigned(3 downto 0);
    signal parallel_reg  : std_logic_vector(7 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt           <= (others => '0');
                parallel_reg  <= (others => '0');
                dout_valid    <= '0';
            else
                dout_valid <= '0';

                if din_valid = '1' then
                    parallel_reg <= parallel_reg(6 downto 0) & din_serial;

                    if cnt = to_unsigned(7, cnt'length) then
                        cnt        <= (others => '0');
                        dout_valid <= '1';
                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    dout_parallel <= parallel_reg;

end rtl;
