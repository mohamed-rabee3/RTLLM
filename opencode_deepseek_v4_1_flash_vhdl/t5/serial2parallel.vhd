library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial2parallel is
    port (
        clk           : in  STD_LOGIC;
        rst_n         : in  STD_LOGIC;
        din_serial    : in  STD_LOGIC;
        din_valid     : in  STD_LOGIC;
        dout_parallel : out STD_LOGIC_VECTOR(7 downto 0);
        dout_valid    : out STD_LOGIC
    );
end serial2parallel;

architecture Behavioral of serial2parallel is
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0);
    signal cnt       : UNSIGNED(3 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            shift_reg  <= (others => '0');
            cnt        <= (others => '0');
            dout_valid <= '0';
        elsif rising_edge(clk) then
            dout_valid <= '0';

            if din_valid = '1' then
                shift_reg <= shift_reg(6 downto 0) & din_serial;

                if cnt = to_unsigned(7, 4) then
                    cnt        <= (others => '0');
                    dout_valid <= '1';
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    dout_parallel <= shift_reg;

end Behavioral;
