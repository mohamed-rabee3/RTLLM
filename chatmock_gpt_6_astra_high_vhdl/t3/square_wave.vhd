library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_wave is
    port (
        clk      : in  std_logic;
        freq     : in  std_logic_vector(7 downto 0);
        wave_out : out std_logic
    );
end entity square_wave;

architecture rtl of square_wave is
    signal count    : unsigned(7 downto 0) := (others => '0');
    signal wave_reg : std_logic := '0';
begin
    wave_out <= wave_reg;

    process (clk)
    begin
        if rising_edge(clk) then
            if count = (unsigned(freq) - to_unsigned(1, 8)) then
                count    <= (others => '0');
                wave_reg <= not wave_reg;
            else
                count <= count + to_unsigned(1, 8);
            end if;
        end if;
    end process;
end architecture rtl;
