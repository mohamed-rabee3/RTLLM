library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial2parallel is
    Port (
        clk           : in  std_logic;
        rst_n         : in  std_logic;
        din_serial    : in  std_logic;
        din_valid     : in  std_logic;
        dout_parallel : out std_logic_vector(7 downto 0);
        dout_valid    : out std_logic
    );
end serial2parallel;

architecture rtl of serial2parallel is
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt       : unsigned(3 downto 0) := (others => '0');
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            shift_reg     <= (others => '0');
            cnt           <= (others => '0');
            dout_parallel <= (others => '0');
            dout_valid    <= '0';
        elsif rising_edge(clk) then
            if din_valid = '1' then
                shift_reg <= shift_reg(6 downto 0) & din_serial;

                if cnt = 7 then
                    dout_parallel <= shift_reg(6 downto 0) & din_serial;
                    dout_valid    <= '1';
                    cnt           <= (others => '0');
                else
                    dout_valid <= '0';
                    cnt        <= cnt + 1;
                end if;
            else
                dout_valid <= '0';
            end if;
        end if;
    end process;

end rtl;
