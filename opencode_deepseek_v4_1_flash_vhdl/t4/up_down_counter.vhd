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
    signal count_reg : unsigned(15 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count_reg <= (others => '0');
            elsif up_down = '1' then
                count_reg <= count_reg + 1;
            else
                count_reg <= count_reg - 1;
            end if;
        end if;
    end process;

    count <= std_logic_vector(count_reg);
end Behavioral;
