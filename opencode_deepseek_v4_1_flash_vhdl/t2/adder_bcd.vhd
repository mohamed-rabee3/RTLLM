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

architecture rtl of adder_bcd is
begin
    process(A, B, Cin)
        variable a_ext    : unsigned(4 downto 0);
        variable b_ext    : unsigned(4 downto 0);
        variable cin_ext  : unsigned(4 downto 0);
        variable sum_bin  : unsigned(4 downto 0);
        variable sum_corr : unsigned(4 downto 0);
    begin
        a_ext   := resize(unsigned(A), 5);
        b_ext   := resize(unsigned(B), 5);
        cin_ext := (others => '0');
        cin_ext(0) := Cin;

        sum_bin := a_ext + b_ext + cin_ext;

        if sum_bin > to_unsigned(9, 5) then
            sum_corr := sum_bin + to_unsigned(6, 5);
            Cout <= '1';
        else
            sum_corr := sum_bin;
            Cout <= '0';
        end if;

        Sum <= std_logic_vector(sum_corr(3 downto 0));
    end process;
end rtl;
