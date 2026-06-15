library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity div_16bit is
    port (
        A      : in  STD_LOGIC_VECTOR(15 downto 0);
        B      : in  STD_LOGIC_VECTOR(7 downto 0);
        result : out STD_LOGIC_VECTOR(15 downto 0);
        odd    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end div_16bit;

architecture Behavioral of div_16bit is
    signal a_reg : STD_LOGIC_VECTOR(15 downto 0);
    signal b_reg : STD_LOGIC_VECTOR(7 downto 0);
begin

    -- First combinational process: registers the inputs
    process(A, B)
    begin
        a_reg <= A;
        b_reg <= B;
    end process;

    -- Second combinational process: performs the division algorithm
    process(a_reg, b_reg)
        variable rem      : UNSIGNED(8 downto 0);
        variable quot     : UNSIGNED(15 downto 0);
        variable divisor  : UNSIGNED(7 downto 0);
        variable dividend : UNSIGNED(15 downto 0);
    begin
        dividend := UNSIGNED(a_reg);
        divisor  := UNSIGNED(b_reg);
        rem      := (others => '0');
        quot     := (others => '0');

        -- Shift-and-subtract restoring division for 16-bit dividend, 8-bit divisor
        for i in 15 downto 0 loop
            -- Shift remainder left by one and bring in the next dividend bit (MSB first)
            rem := rem(7 downto 0) & dividend(i);
            if rem >= ('0' & divisor) then
                rem       := rem - ('0' & divisor);
                quot(i)   := '1';
            else
                quot(i)   := '0';
            end if;
        end loop;

        result <= STD_LOGIC_VECTOR(quot);
        odd    <= STD_LOGIC_VECTOR(RESIZE(rem(7 downto 0), 16));  -- remainder padded to 16 bits
    end process;

end Behavioral;