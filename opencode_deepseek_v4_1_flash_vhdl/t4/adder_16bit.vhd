library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_8bit is
    Port (
        a    : in  STD_LOGIC_VECTOR(7 downto 0);
        b    : in  STD_LOGIC_VECTOR(7 downto 0);
        Cin  : in  STD_LOGIC;
        y    : out STD_LOGIC_VECTOR(7 downto 0);
        Co   : out STD_LOGIC
    );
end adder_8bit;

architecture Behavioral of adder_8bit is
    signal sum : STD_LOGIC_VECTOR(8 downto 0);
begin
    sum <= ('0' & a) + ('0' & b) + ("00000000" & Cin);
    y   <= sum(7 downto 0);
    Co  <= sum(8);
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_16bit is
    Port (
        a    : in  STD_LOGIC_VECTOR(15 downto 0);
        b    : in  STD_LOGIC_VECTOR(15 downto 0);
        Cin  : in  STD_LOGIC;
        y    : out STD_LOGIC_VECTOR(15 downto 0);
        Co   : out STD_LOGIC
    );
end adder_16bit;

architecture Structural of adder_16bit is

    component adder_8bit
        Port (
            a    : in  STD_LOGIC_VECTOR(7 downto 0);
            b    : in  STD_LOGIC_VECTOR(7 downto 0);
            Cin  : in  STD_LOGIC;
            y    : out STD_LOGIC_VECTOR(7 downto 0);
            Co   : out STD_LOGIC
        );
    end component;

    signal carry_mid : STD_LOGIC;

begin

    u_adder_low : adder_8bit
        port map (
            a    => a(7 downto 0),
            b    => b(7 downto 0),
            Cin  => Cin,
            y    => y(7 downto 0),
            Co   => carry_mid
        );

    u_adder_high : adder_8bit
        port map (
            a    => a(15 downto 8),
            b    => b(15 downto 8),
            Cin  => carry_mid,
            y    => y(15 downto 8),
            Co   => Co
        );

end Structural;
