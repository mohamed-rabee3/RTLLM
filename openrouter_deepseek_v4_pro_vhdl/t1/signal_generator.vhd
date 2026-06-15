library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity signal_generator is
    Port ( clk   : in  STD_LOGIC;
           rst_n : in  STD_LOGIC;
           wave  : out STD_LOGIC_VECTOR(4 downto 0));
end signal_generator;

architecture Behavioral of signal_generator is
    signal wave_reg : unsigned(4 downto 0) := (others => '0');
    signal state    : STD_LOGIC := '0';
begin
    wave <= std_logic_vector(wave_reg);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            wave_reg <= (others => '0');
            state    <= '0';
        elsif rising_edge(clk) then
            if state = '0' then
                -- Incrementing phase
                if wave_reg = 30 then
                    wave_reg <= wave_reg + 1;   -- becomes 31
                    state    <= '1';            -- transition to decrementing
                else
                    wave_reg <= wave_reg + 1;
                    -- state holds '0'
                end if;
            else
                -- Decrementing phase (state = '1')
                if wave_reg = 1 then
                    wave_reg <= wave_reg - 1;   -- becomes 0
                    state    <= '0';            -- transition to incrementing
                else
                    wave_reg <= wave_reg - 1;
                    -- state holds '1'
                end if;
            end if;
        end if;
    end process;
end Behavioral;