library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity JC_counter is
    Port ( clk   : in  STD_LOGIC;
           rst_n : in  STD_LOGIC;
           Q     : out STD_LOGIC_VECTOR(63 downto 0)
         );
end entity JC_counter;

architecture Behavioral of JC_counter is

    -- Internal counter register
    signal count_reg : std_logic_vector(63 downto 0) := (others => '0');

begin

    -- Connect internal register to output port
    Q <= count_reg;

    -- Counter process with asynchronous active-low reset
    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            -- Reset condition: all bits to zero
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Update rule on rising clock edge
            if (count_reg(0) = '0') then
                -- When LSB is 0, shift right and set MSB to 1
                count_reg <= '1' & count_reg(63 downto 1);
            else
                -- When LSB is 1, shift right and set MSB to 0
                count_reg <= '0' & count_reg(63 downto 1);
            end if;
        end if;
    end process;

end architecture Behavioral;