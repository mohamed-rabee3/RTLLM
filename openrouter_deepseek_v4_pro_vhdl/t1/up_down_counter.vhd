library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity up_down_counter is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        up_down : in  STD_LOGIC;
        count   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end up_down_counter;

architecture Behavioral of up_down_counter is
    signal counter_reg : UNSIGNED(15 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter_reg <= (others => '0');
            else
                if up_down = '1' then
                    counter_reg <= counter_reg + 1;
                else
                    counter_reg <= counter_reg - 1;
                end if;
            end if;
        end if;
    end process;

    count <= STD_LOGIC_VECTOR(counter_reg);

end Behavioral;