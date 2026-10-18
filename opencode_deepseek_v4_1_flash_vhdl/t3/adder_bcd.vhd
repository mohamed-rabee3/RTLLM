library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_bcd is
    Port (
        A    : in  STD_LOGIC_VECTOR(3 downto 0);
        B    : in  STD_LOGIC_VECTOR(3 downto 0);
        Cin  : in  STD_LOGIC;
        Sum  : out STD_LOGIC_VECTOR(3 downto 0);
        Cout : out STD_LOGIC
    );
end adder_bcd;

architecture Behavioral of adder_bcd is
begin
    process(A, B, Cin)
        variable a_u    : unsigned(4 downto 0);
        variable b_u    : unsigned(4 downto 0);
        variable cin_u  : unsigned(4 downto 0);
        variable sum_u  : unsigned(4 downto 0);
        variable corr_u : unsigned(4 downto 0);
    begin
        a_u := resize(unsigned(A), 5);
        b_u := resize(unsigned(B), 5);
        cin_u := (others => '0');
        if Cin = '1' then
            cin_u(0) := '1';
        end if;

        sum_u := a_u + b_u + cin_u;

        if sum_u > to_unsigned(9, 5) then
            corr_u := sum_u + to_unsigned(6, 5);
            Cout <= '1';
        else
            corr_u := sum_u;
            Cout <= '0';
        end if;

        Sum <= std_logic_vector(corr_u(3 downto 0));
    end process;
end Behavioral;
