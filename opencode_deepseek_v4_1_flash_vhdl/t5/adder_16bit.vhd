library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_16bit is
    Port (
        a    : in  STD_LOGIC_VECTOR(15 downto 0);
        b    : in  STD_LOGIC_VECTOR(15 downto 0);
        Cin  : in  STD_LOGIC;
        y    : out STD_LOGIC_VECTOR(15 downto 0);
        Co   : out STD_LOGIC
    );
end adder_16bit;

architecture rtl of adder_16bit is
    signal y_low     : STD_LOGIC_VECTOR(7 downto 0);
    signal y_high    : STD_LOGIC_VECTOR(7 downto 0);
    signal carry_mid : STD_LOGIC;
    signal carry_out : STD_LOGIC;

    component adder_8bit
        Port (
            a    : in  STD_LOGIC_VECTOR(7 downto 0);
            b    : in  STD_LOGIC_VECTOR(7 downto 0);
            Cin  : in  STD_LOGIC;
            y    : out STD_LOGIC_VECTOR(7 downto 0);
            Co   : out STD_LOGIC
        );
    end component;
begin
    u_low : adder_8bit
        port map (
            a    => a(7 downto 0),
            b    => b(7 downto 0),
            Cin  => Cin,
            y    => y_low,
            Co   => carry_mid
        );

    u_high : adder_8bit
        port map (
            a    => a(15 downto 8),
            b    => b(15 downto 8),
            Cin  => carry_mid,
            y    => y_high,
            Co   => carry_out
        );

    y  <= y_high & y_low;
    Co <= carry_out;
end rtl;

entity adder_8bit is
    Port (
        a    : in  STD_LOGIC_VECTOR(7 downto 0);
        b    : in  STD_LOGIC_VECTOR(7 downto 0);
        Cin  : in  STD_LOGIC;
        y    : out STD_LOGIC_VECTOR(7 downto 0);
        Co   : out STD_LOGIC
    );
end adder_8bit;

architecture rtl of adder_8bit is
begin
    process(a, b, Cin)
        variable a_ext   : unsigned(8 downto 0);
        variable b_ext   : unsigned(8 downto 0);
        variable cin_ext : unsigned(8 downto 0);
        variable sum_ext : unsigned(8 downto 0);
    begin
        a_ext := resize(unsigned(a), 9);
        b_ext := resize(unsigned(b), 9);
        cin_ext := (others => '0');
        cin_ext(0) := Cin;

        sum_ext := a_ext + b_ext + cin_ext;

        y  <= std_logic_vector(sum_ext(7 downto 0));
        Co <= sum_ext(8);
    end process;
end rtl;
