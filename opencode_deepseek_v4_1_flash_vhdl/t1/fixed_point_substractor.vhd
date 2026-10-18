library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_subtractor is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end entity fixed_point_subtractor;

architecture rtl of fixed_point_subtractor is
    signal res : std_logic_vector(N-1 downto 0);
begin
    process(a, b)
        variable tmp : std_logic_vector(N-1 downto 0);
    begin
        tmp := std_logic_vector(signed(a) - signed(b));
        res <= tmp;

        if tmp = (tmp'range => '0') then
            c <= (others => '0');
        else
            c <= tmp;
        end if;
    end process;
end architecture rtl;
