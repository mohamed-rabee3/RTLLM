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
        variable a_signed : signed(N-1 downto 0);
        variable b_signed : signed(N-1 downto 0);
        variable diff     : signed(N-1 downto 0);
    begin
        a_signed := signed(a);
        b_signed := signed(b);
        diff     := a_signed - b_signed;

        if diff = 0 then
            res <= (others => '0');
        else
            res <= std_logic_vector(diff);
        end if;
    end process;

    c <= res;
end architecture rtl;
