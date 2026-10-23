library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_8bit is
    Port (
        a : in  STD_LOGIC_VECTOR (7 downto 0);
        b : in  STD_LOGIC_VECTOR (7 downto 0);
        Cin : in  STD_LOGIC;
        y : out STD_LOGIC_VECTOR (7 downto 0);
        Co : out STD_LOGIC
    );
end adder_8bit;

architecture rtl of adder_8bit is
    signal sum     : unsigned(8 downto 0);
    signal cin_vec : unsigned(8 downto 0);
begin
    cin_vec <= (0 => Cin, others => '0');
    sum <= resize(unsigned(a), 9) + resize(unsigned(b), 9) + cin_vec;

    y  <= std_logic_vector(sum(7 downto 0));
    Co <= sum(8);
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_16bit is
    Port (
        a  : in  STD_LOGIC_VECTOR (15 downto 0);
        b  : in  STD_LOGIC_VECTOR (15 downto 0);
        Cin : in  STD_LOGIC;
        y  : out STD_LOGIC_VECTOR (15 downto 0);
        Co : out STD_LOGIC
    );
end adder_16bit;

architecture structural of adder_16bit is
    component adder_8bit
        Port (
            a   : in  STD_LOGIC_VECTOR (7 downto 0);
            b   : in  STD_LOGIC_VECTOR (7 downto 0);
            Cin : in  STD_LOGIC;
            y   : out STD_LOGIC_VECTOR (7 downto 0);
            Co  : out STD_LOGIC
        );
    end component;

    signal carry_mid : STD_LOGIC;
begin
    u_low : adder_8bit
        port map (
            a   => a(7 downto 0),
            b   => b(7 downto 0),
            Cin => Cin,
            y   => y(7 downto 0),
            Co  => carry_mid
        );

    u_high : adder_8bit
        port map (
            a   => a(15 downto 8),
            b   => b(15 downto 8),
            Cin => carry_mid,
            y   => y(15 downto 8),
            Co  => Co
        );
end structural;
