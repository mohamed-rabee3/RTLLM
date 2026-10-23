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

architecture RTL of signal_generator is
    signal state    : STD_LOGIC := '0';
    signal wave_reg : UNSIGNED (4 downto 0) := (others => '0');
begin

    wave <= STD_LOGIC_VECTOR(wave_reg);

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= '0';
            wave_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when '0' =>
                    if wave_reg = to_unsigned(31, wave_reg'length) then
                        wave_reg <= wave_reg - 1;
                        state    <= '1';
                    else
                        wave_reg <= wave_reg + 1;
                    end if;
                when '1' =>
                    if wave_reg = to_unsigned(0, wave_reg'length) then
                        wave_reg <= wave_reg + 1;
                        state    <= '0';
                    else
                        wave_reg <= wave_reg - 1;
                    end if;
                when others =>
                    state    <= '0';
                    wave_reg <= (others => '0');
            end case;
        end if;
    end process;

end RTL;
