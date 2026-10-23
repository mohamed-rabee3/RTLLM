library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator_4bit is
    Port (
        A : in STD_LOGIC_VECTOR(3 downto 0);
        B : in STD_LOGIC_VECTOR(3 downto 0);
        A_greater : out STD_LOGIC;
        A_equal : out STD_LOGIC;
        A_less : out STD_LOGIC
    );
end comparator_4bit;

architecture Behavioral of comparator_4bit is
begin
    process(A, B)
        variable A_ext : unsigned(4 downto 0);
        variable B_ext : unsigned(4 downto 0);
        variable diff  : unsigned(4 downto 0);
    begin
        A_ext := (others => '0');
        B_ext := (others => '0');

        A_ext(3 downto 0) := unsigned(A);
        B_ext(3 downto 0) := unsigned(B);

        diff := A_ext - B_ext;

        A_greater <= '0';
        A_equal   <= '0';
        A_less    <= '0';

        if diff(4) = '1' then
            A_less <= '1';
        elsif diff(3 downto 0) = 0 then
            A_equal <= '1';
        else
            A_greater <= '1';
        end if;
    end process;
end Behavioral;
