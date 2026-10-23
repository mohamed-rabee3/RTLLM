library ieee;
use ieee.std_logic_1164.all;

entity adder_8bit is
    port (
        a   : in  std_logic_vector(7 downto 0);
        b   : in  std_logic_vector(7 downto 0);
        Cin : in  std_logic;
        y   : out std_logic_vector(7 downto 0);
        Co  : out std_logic
    );
end entity adder_8bit;

architecture rtl of adder_8bit is
    signal carry : std_logic_vector(8 downto 0);
begin
    carry(0) <= Cin;

    gen_bits : for i in 0 to 7 generate
        y(i) <= a(i) xor b(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or
                        (a(i) and carry(i)) or
                        (b(i) and carry(i));
    end generate gen_bits;

    Co <= carry(8);
end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;

entity adder_16bit is
    port (
        a   : in  std_logic_vector(15 downto 0);
        b   : in  std_logic_vector(15 downto 0);
        Cin : in  std_logic;
        y   : out std_logic_vector(15 downto 0);
        Co  : out std_logic
    );
end entity adder_16bit;

architecture rtl of adder_16bit is
    signal carry_mid : std_logic;
begin
    lower_adder : entity work.adder_8bit(rtl)
        port map (
            a   => a(7 downto 0),
            b   => b(7 downto 0),
            Cin => Cin,
            y   => y(7 downto 0),
            Co  => carry_mid
        );

    upper_adder : entity work.adder_8bit(rtl)
        port map (
            a   => a(15 downto 8),
            b   => b(15 downto 8),
            Cin => carry_mid,
            y   => y(15 downto 8),
            Co  => Co
        );
end architecture rtl;
