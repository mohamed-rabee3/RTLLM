library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM is
    port (
        addr : in  STD_LOGIC_VECTOR(7 downto 0);
        dout : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity ROM;

architecture rtl of ROM is
    type rom_type is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);

    constant mem : rom_type := (
        0      => X"A0A0",
        1      => X"B1B1",
        2      => X"C2C2",
        3      => X"D3D3",
        others => X"0000"
    );
begin
    dout <= mem(to_integer(unsigned(addr)));
end architecture rtl;
