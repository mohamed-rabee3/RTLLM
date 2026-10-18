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
    process(A, B, Cin)
        variable sum_bin : unsigned(4 downto 0);
        variable cin_u   : unsigned(4 downto 0);
    begin
        cin_u   := (0 => Cin, others => '0');
        sum_bin := unsigned('0' & A) + unsigned('0' & B) + cin_u;

        if sum_bin > 9 then
            Sum  <= std_logic_vector(sum_bin(3 downto 0) + to_unsigned(6, 4));
            Cout <= '1';
        else
            Sum  <= std_logic_vector(sum_bin(3 downto 0));
            Cout <= '0';
        end if;
    end process;
end architecture rtl;
