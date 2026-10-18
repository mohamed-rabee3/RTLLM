library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity square_wave is
    Port (
        clk      : in  STD_LOGIC;
        freq     : in  STD_LOGIC_VECTOR(7 downto 0);
        wave_out : out STD_LOGIC
    );
end square_wave;

architecture Behavioral of square_wave is
    signal count    : unsigned(7 downto 0) := (others => '0');
    signal wave_reg : std_logic := '0';
begin
    process(clk)
        variable freq_minus_1 : unsigned(7 downto 0);
    begin
        if rising_edge(clk) then
            freq_minus_1 := unsigned(freq) - 1;
            if count = freq_minus_1 then
                count    <= (others => '0');
                wave_reg <= not wave_reg;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    wave_out <= wave_reg;
end Behavioral;
