library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_adder is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in std_logic_vector(N-1 downto 0);
        b : in std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end fixed_point_adder;

architecture behavioral of fixed_point_adder is
    signal res : std_logic_vector(N-1 downto 0);
begin
    process(a, b)
    begin
        res <= std_logic_vector(signed(a) + signed(b));
    end process;
    c <= res;
end behavioral;
