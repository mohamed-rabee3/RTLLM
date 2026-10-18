library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity add_CLA is
    Port (
        a      : in  STD_LOGIC_VECTOR(15 downto 0);
        b      : in  STD_LOGIC_VECTOR(15 downto 0);
        result : out STD_LOGIC_VECTOR(16 downto 0)
    );
end add_CLA;

architecture Behavioral of add_CLA is
begin
    process(a, b)
        variable g : STD_LOGIC_VECTOR(15 downto 0);
        variable p : STD_LOGIC_VECTOR(15 downto 0);
        variable c : STD_LOGIC_VECTOR(16 downto 0);
    begin
        c(0) := '0';

        for i in 0 to 15 loop
            g(i) := a(i) and b(i);
            p(i) := a(i) xor b(i);
            c(i + 1) := g(i) or (p(i) and c(i));
            result(i) <= p(i) xor c(i);
        end loop;

        result(16) <= c(16);
    end process;
end Behavioral;
