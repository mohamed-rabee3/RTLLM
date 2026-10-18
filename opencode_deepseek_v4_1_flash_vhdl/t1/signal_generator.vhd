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

    process(clk, rst_n)
        variable wave_v  : UNSIGNED(4 downto 0);
        variable state_v : STD_LOGIC;
    begin
        if rst_n = '0' then
            state    <= '0';
            wave_reg <= (others => '0');
        elsif rising_edge(clk) then
            wave_v  := wave_reg;
            state_v := state;

            case state_v is
                when '0' =>
                    wave_v := wave_v + 1;
                    if wave_v = 31 then
                        state_v := '1';
                    end if;
                when '1' =>
                    wave_v := wave_v - 1;
                    if wave_v = 0 then
                        state_v := '0';
                    end if;
                when others =>
                    state_v := '0';
                    wave_v  := (others => '0');
            end case;

            wave_reg <= wave_v;
            state    <= state_v;
        end if;
    end process;

    wave <= STD_LOGIC_VECTOR(wave_reg);

end RTL;
