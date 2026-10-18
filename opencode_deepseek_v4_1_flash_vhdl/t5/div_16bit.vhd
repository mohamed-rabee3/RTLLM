library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity div_16bit is
    Port (
        A      : in  STD_LOGIC_VECTOR (15 downto 0);
        B      : in  STD_LOGIC_VECTOR (7 downto 0);
        result : out STD_LOGIC_VECTOR (15 downto 0);
        odd    : out STD_LOGIC_VECTOR (15 downto 0)
    );
end div_16bit;

architecture Behavioral of div_16bit is
    signal a_reg : unsigned(15 downto 0);
    signal b_reg : unsigned(7 downto 0);
begin

    -- First combinational process: register the inputs
    process(A, B)
    begin
        a_reg <= unsigned(A);
        b_reg <= unsigned(B);
    end process;

    -- Second combinational process: restoring division
    process(a_reg, b_reg)
        variable rem   : unsigned(8 downto 0);
        variable quot  : unsigned(15 downto 0);
        variable b_ext : unsigned(8 downto 0);
        variable i     : integer;
    begin
        rem   := (others => '0');
        quot  := (others => '0');
        b_ext := resize(b_reg, rem'length);

        if b_reg = 0 then
            result <= (others => '0');
            odd    <= (others => '0');
        else
            for i in 15 downto 0 loop
                rem := (rem(7 downto 0) & a_reg(i));
                if rem >= b_ext then
                    rem := rem - b_ext;
                    quot(i) := '1';
                else
                    quot(i) := '0';
                end if;
            end loop;
            result <= std_logic_vector(quot);
            odd    <= std_logic_vector(resize(rem, 16));
        end if;
    end process;

end Behavioral;
