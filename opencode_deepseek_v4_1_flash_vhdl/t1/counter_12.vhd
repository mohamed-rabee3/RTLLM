library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_12 is
    Port (
        rst_n       : in  std_logic;
        clk         : in  std_logic;
        valid_count : in  std_logic;
        out         : out std_logic_vector(3 downto 0)
    );
end counter_12;

architecture rtl of counter_12 is
    signal count_reg : std_logic_vector(3 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            count_reg <= "0000";
        elsif rising_edge(clk) then
            if valid_count = '1' then
                if count_reg = "1011" then
                    count_reg <= "0000";
                else
                    count_reg <= std_logic_vector(unsigned(count_reg) + 1);
                end if;
            end if;
        end if;
    end process;

    out <= count_reg;

end rtl;
