library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port (
        addr : in  std_logic_vector(7 downto 0);
        dout : out std_logic_vector(15 downto 0)
    );
end entity ROM;

architecture rtl of ROM is
    type rom_array_t is array (0 to 255) of std_logic_vector(15 downto 0);

    constant mem : rom_array_t := (
        0      => x"A0A0",
        1      => x"B1B1",
        2      => x"C2C2",
        3      => x"D3D3",
        others => x"0000"
    );
begin
    dout <= mem(to_integer(unsigned(addr)));
end architecture rtl;
