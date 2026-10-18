library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_down_counter is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        up_down : in  std_logic;
        count   : out std_logic_vector(15 downto 0)
    );
end entity up_down_counter;

architecture rtl of up_down_counter is
    signal counter_reg : unsigned(15 downto 0);
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter_reg <= (others => '0');
            elsif up_down = '1' then
                counter_reg <= counter_reg + 1;
            else
                counter_reg <= counter_reg - 1;
            end if;
        end if;
    end process;

    count <= std_logic_vector(counter_reg);
end architecture rtl;
