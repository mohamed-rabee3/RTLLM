library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port (
        addr : in  std_logic_vector(7 downto 0);
        dout : out std_logic_vector(15 downto 0)
    );
end entity ROM;

architecture behavioral of ROM is
    -- Define a memory type with 256 locations of 16 bits each
    type memory_type is array (0 to 255) of std_logic_vector(15 downto 0);
    
    -- ROM content initialization:
    -- Locations 0 to 3 are preloaded with specified values;
    -- all other locations default to 0x0000 (can be changed as needed).
    constant mem : memory_type := (
        0      => x"A0A0",
        1      => x"B1B1",
        2      => x"C2C2",
        3      => x"D3D3",
        others => x"0000"
    );
begin
    -- Combinational read: output the data at the selected address
    dout <= mem(to_integer(unsigned(addr)));
end architecture behavioral;