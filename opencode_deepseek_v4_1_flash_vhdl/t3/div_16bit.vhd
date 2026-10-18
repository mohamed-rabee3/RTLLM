library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity div_16bit is
    Port ( A : in  STD_LOGIC_VECTOR (15 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);
           result : out  STD_LOGIC_VECTOR (15 downto 0);
           odd : out  STD_LOGIC_VECTOR (15 downto 0));
end div_16bit;

architecture Behavioral of div_16bit is
    signal a_reg : unsigned(15 downto 0);
    signal b_reg : unsigned(7 downto 0);
begin

    -- First combinational block: register inputs
    process(A, B)
    begin
        a_reg <= unsigned(A);
        b_reg <= unsigned(B);
    end process;

    -- Second combinational block: perform division
    process(a_reg, b_reg)
        variable rem : unsigned(15 downto 0);
        variable quot : unsigned(15 downto 0);
        variable divisor : unsigned(15 downto 0);
    begin
        rem := (others => '0');
        quot := (others => '0');
        divisor := resize(b_reg, 16);

        for i in 15 downto 0 loop
            rem := rem(14 downto 0) & a_reg(i);
            if rem >= divisor then
                rem := rem - divisor;
                quot(i) := '1';
            else
                quot(i) := '0';
            end if;
        end loop;

        result <= std_logic_vector(quot);
        odd <= std_logic_vector(rem);
    end process;

end Behavioral;
