library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_bcd is
    Port (
        A    : in  STD_LOGIC_VECTOR (3 downto 0);
        B    : in  STD_LOGIC_VECTOR (3 downto 0);
        Cin  : in  STD_LOGIC;
        Sum  : out STD_LOGIC_VECTOR (3 downto 0);
        Cout : out STD_LOGIC
    );
end adder_bcd;

architecture Behavioral of adder_bcd is
begin
    process(A, B, Cin)
        variable sum_bin  : unsigned(4 downto 0);
        variable sum_corr : unsigned(4 downto 0);
        variable cin_ext  : unsigned(4 downto 0);
    begin
        cin_ext := (others => '0');
        if Cin = '1' then
            cin_ext(0) := '1';
        end if;

        sum_bin := resize(unsigned(A), 5) + resize(unsigned(B), 5) + cin_ext;

        if sum_bin > 9 then
            sum_corr := sum_bin + to_unsigned(6, 5);
            Sum      <= std_logic_vector(sum_corr(3 downto 0));
            Cout     <= '1';
        else
            Sum  <= std_logic_vector(sum_bin(3 downto 0));
            Cout <= '0';
        end if;
    end process;
end Behavioral;
