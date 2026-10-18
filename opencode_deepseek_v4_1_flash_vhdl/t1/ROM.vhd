library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM is
    Port (
        addr : in STD_LOGIC_VECTOR (7 downto 0);
        dout : out STD_LOGIC_VECTOR (15 downto 0)
    );
end ROM;

architecture Behavioral of ROM is
    type rom_type is array (0 to 255) of std_logic_vector(15 downto 0);
    constant mem : rom_type := (
        0 => "1010000010100000",
        1 => "1011000110110001",
        2 => "1100001011000010",
        3 => "1101001111010011",
        others => (others => '0')
    );
begin
    process(addr)
    begin
        dout <= mem(to_integer(unsigned(addr)));
    end process;
end Behavioral;
