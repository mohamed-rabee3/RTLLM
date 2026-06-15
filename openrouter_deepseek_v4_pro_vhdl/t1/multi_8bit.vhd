library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_8bit is
    Port (
        A       : in  std_logic_vector(7 downto 0);
        B       : in  std_logic_vector(7 downto 0);
        product : out std_logic_vector(15 downto 0)
    );
end multi_8bit;

architecture Behavioral of multi_8bit is
begin
    process(A, B)
        variable temp_product : unsigned(15 downto 0);
        variable shifted_A    : unsigned(15 downto 0);
    begin
        -- Initialize the product accumulator and the shifted multiplicand
        temp_product := (others => '0');
        shifted_A    := "00000000" & unsigned(A);  -- Position A at the least significant bits

        -- Iterate through each bit of the multiplier B
        for i in 0 to 7 loop
            -- If the current bit of B is set, add the shifted multiplicand
            if B(i) = '1' then
                temp_product := temp_product + shifted_A;
            end if;
            -- Logically shift the multiplicand left by one bit for the next iteration
            shifted_A := shifted_A(14 downto 0) & '0';
        end loop;

        -- Drive the output
        product <= std_logic_vector(temp_product);
    end process;
end Behavioral;