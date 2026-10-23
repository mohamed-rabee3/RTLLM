library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity signal_generator is
    Port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        wave  : out STD_LOGIC_VECTOR (4 downto 0)
    );
end signal_generator;

architecture rtl of signal_generator is
    signal state    : STD_LOGIC := '0';
    signal wave_reg : unsigned(4 downto 0) := (others => '0');
begin
    wave <= std_logic_vector(wave_reg);

    process(clk, rst_n)
        variable next_wave : unsigned(4 downto 0);
    begin
        if rst_n = '0' then
            state    <= '0';
            wave_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when '0' =>
                    next_wave := wave_reg + 1;
                    wave_reg <= next_wave;
                    if next_wave = 31 then
                        state <= '1';
                    else
                        state <= '0';
                    end if;

                when '1' =>
                    next_wave := wave_reg - 1;
                    wave_reg <= next_wave;
                    if next_wave = 0 then
                        state <= '0';
                    else
                        state <= '1';
                    end if;

                when others =>
                    state    <= '0';
                    wave_reg <= (others => '0');
            end case;
        end if;
    end process;
end rtl;
