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
end adder_8bit;

architecture rtl of adder_8bit is
begin
    process(a, b, Cin)
        variable sum : unsigned(8 downto 0);
    begin
        sum := resize(unsigned(a), 9) + resize(unsigned(b), 9);
        if Cin = '1' then
            sum := sum + to_unsigned(1, 9);
        end if;

        y  <= std_logic_vector(sum(7 downto 0));
        Co <= sum(8);
    end process;
end rtl;

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
end adder_16bit;

architecture rtl of adder_16bit is
    signal c_mid  : std_logic;
    signal y_low  : std_logic_vector(7 downto 0);
    signal y_high : std_logic_vector(7 downto 0);
begin
    u_low : entity work.adder_8bit
        port map (
            a   => a(7 downto 0),
            b   => b(7 downto 0),
            Cin => Cin,
            y   => y_low,
            Co  => c_mid
        );

    u_high : entity work.adder_8bit
        port map (
            a   => a(15 downto 8),
            b   => b(15 downto 8),
            Cin => c_mid,
            y   => y_high,
            Co  => Co
        );

    y <= y_high & y_low;
end rtl;
