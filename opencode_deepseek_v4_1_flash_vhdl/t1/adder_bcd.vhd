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
        variable binary_sum    : unsigned(4 downto 0);
        variable corrected_sum : unsigned(4 downto 0);
    begin
        binary_sum := resize(unsigned(A), 5) + resize(unsigned(B), 5);

        if Cin = '1' then
            binary_sum := binary_sum + to_unsigned(1, 5);
        end if;

        if binary_sum > to_unsigned(9, 5) then
            corrected_sum := binary_sum + to_unsigned(6, 5);
            Sum  <= std_logic_vector(corrected_sum(3 downto 0));
            Cout <= '1';
        else
            Sum  <= std_logic_vector(binary_sum(3 downto 0));
            Cout <= '0';
        end if;
    end process;
end Behavioral;
