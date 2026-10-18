library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_bcd is
    port (
        A    : in  std_logic_vector(3 downto 0);
        B    : in  std_logic_vector(3 downto 0);
        Cin  : in  std_logic;
        Sum  : out std_logic_vector(3 downto 0);
        Cout : out std_logic
    );
end entity adder_bcd;

architecture rtl of adder_bcd is
begin
    process (A, B, Cin)
        variable binary_sum    : unsigned(4 downto 0);
        variable corrected_sum : unsigned(4 downto 0);
        variable carry_in      : unsigned(4 downto 0);
    begin
        carry_in := (others => '0');
        carry_in(0) := Cin;

        binary_sum := resize(unsigned(A), 5)
                    + resize(unsigned(B), 5)
                    + carry_in;

        if binary_sum > to_unsigned(9, 5) then
            corrected_sum := binary_sum + to_unsigned(6, 5);
            Cout <= '1';
        else
            corrected_sum := binary_sum;
            Cout <= '0';
        end if;

        Sum <= std_logic_vector(corrected_sum(3 downto 0));
    end process;
end architecture rtl;
