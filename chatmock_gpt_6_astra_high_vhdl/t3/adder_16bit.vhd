library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    signal carry_in : unsigned(8 downto 0);
    signal sum_ext  : unsigned(8 downto 0);
begin
    carry_in <= (0 => Cin, others => '0');

    sum_ext <= resize(unsigned(a), 9)
             + resize(unsigned(b), 9)
             + carry_in;

    y  <= std_logic_vector(sum_ext(7 downto 0));
    Co <= sum_ext(8);
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
