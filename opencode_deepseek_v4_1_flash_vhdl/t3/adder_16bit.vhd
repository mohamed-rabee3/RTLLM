library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_8bit is
    Port (
        A    : in  STD_LOGIC_VECTOR(7 downto 0);
        B    : in  STD_LOGIC_VECTOR(7 downto 0);
        Cin  : in  STD_LOGIC;
        Y    : out STD_LOGIC_VECTOR(7 downto 0);
        Cout : out STD_LOGIC
    );
end adder_8bit;

architecture Behavioral of adder_8bit is
begin
    process(A, B, Cin)
        variable tmp : unsigned(8 downto 0);
    begin
        tmp := ('0' & unsigned(A)) + ('0' & unsigned(B));
        if Cin = '1' then
            tmp := tmp + 1;
        end if;
        Y <= std_logic_vector(tmp(7 downto 0));
        Cout <= tmp(8);
    end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_16bit is
    Port (
        a   : in  STD_LOGIC_VECTOR(15 downto 0);
        b   : in  STD_LOGIC_VECTOR(15 downto 0);
        Cin : in  STD_LOGIC;
        y   : out STD_LOGIC_VECTOR(15 downto 0);
        Co  : out STD_LOGIC
    );
end adder_16bit;

architecture Structural of adder_16bit is
    signal carry_mid : STD_LOGIC;
begin
    u_adder_low: entity work.adder_8bit(Behavioral)
        port map (
            A    => a(7 downto 0),
            B    => b(7 downto 0),
            Cin  => Cin,
            Y    => y(7 downto 0),
            Cout => carry_mid
        );

    u_adder_high: entity work.adder_8bit(Behavioral)
        port map (
            A    => a(15 downto 8),
            B    => b(15 downto 8),
            Cin  => carry_mid,
            Y    => y(15 downto 8),
            Cout => Co
        );
end Structural;
