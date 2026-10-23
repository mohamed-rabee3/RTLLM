library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_generator is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        wave  : out std_logic_vector(4 downto 0)
    );
end entity signal_generator;

architecture rtl of signal_generator is
    signal state    : std_logic;
    signal wave_reg : unsigned(4 downto 0);
begin
    wave <= std_logic_vector(wave_reg);

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= '0';
            wave_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when '0' =>
                    wave_reg <= wave_reg + 1;
                    if wave_reg = to_unsigned(31, wave_reg'length) then
                        state <= '1';
                    end if;

                when '1' =>
                    wave_reg <= wave_reg - 1;
                    if wave_reg = to_unsigned(0, wave_reg'length) then
                        state <= '0';
                    end if;

                when others =>
                    state    <= '0';
                    wave_reg <= (others => '0');
            end case;
        end if;
    end process;
end architecture rtl;
