library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_12 is
    port (
        rst_n       : in  std_logic;
        clk         : in  std_logic;
        valid_count : in  std_logic;
        out_port    : out std_logic_vector(3 downto 0)  -- renamed to avoid keyword conflict
    );
end entity counter_12;

architecture rtl of counter_12 is
    signal count_reg : unsigned(3 downto 0);
begin

    -- Asynchronous active-low reset
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            if valid_count = '1' then
                if count_reg = 11 then
                    count_reg <= (others => '0');
                else
                    count_reg <= count_reg + 1;
                end if;
            end if;
        end if;
    end process;

    -- Drive output
    out_port <= std_logic_vector(count_reg);

end architecture rtl;