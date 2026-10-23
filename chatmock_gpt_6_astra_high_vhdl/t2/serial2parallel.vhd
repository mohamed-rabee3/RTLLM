library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial2parallel is
    port (
        clk           : in  std_logic;
        rst_n         : in  std_logic;
        din_serial    : in  std_logic;
        din_valid     : in  std_logic;
        dout_parallel : out std_logic_vector(7 downto 0);
        dout_valid    : out std_logic
    );
end entity serial2parallel;

architecture rtl of serial2parallel is
    signal cnt       : unsigned(3 downto 0);
    signal shift_reg : std_logic_vector(7 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt           <= (others => '0');
                shift_reg     <= (others => '0');
                dout_parallel <= (others => '0');
                dout_valid    <= '0';
            else
                dout_valid <= '0';

                if din_valid = '1' then
                    shift_reg <= shift_reg(6 downto 0) & din_serial;

                    if cnt = to_unsigned(7, cnt'length) then
                        cnt           <= (others => '0');
                        dout_parallel <= shift_reg(6 downto 0) & din_serial;
                        dout_valid    <= '1';
                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
