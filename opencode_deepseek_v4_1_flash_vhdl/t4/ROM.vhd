library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM is
    port (
        addr : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(15 downto 0)
    );
end ROM;

architecture rtl of ROM is
    type rom_type is array (0 to 255) of std_logic_vector(15 downto 0);

    constant mem : rom_type := (
        0 => x"A0A0",
        1 => x"B1B1",
        2 => x"C2C2",
        3 => x"D3D3",
        others => (others => '0')
    );
begin
    dout <= mem(to_integer(unsigned(addr)));
end rtl;
