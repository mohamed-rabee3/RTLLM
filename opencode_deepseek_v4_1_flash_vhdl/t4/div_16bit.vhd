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

    process(A, B)
    begin
        a_reg <= unsigned(A);
        b_reg <= unsigned(B);
    end process;

    process(a_reg, b_reg)
        variable rem_var : unsigned(15 downto 0);
        variable quo_var : unsigned(15 downto 0);
    begin
        rem_var := (others => '0');
        quo_var := (others => '0');

        for i in 15 downto 0 loop
            rem_var := shift_left(rem_var, 1);
            rem_var(0) := a_reg(i);

            if rem_var >= resize(b_reg, 16) then
                rem_var := rem_var - resize(b_reg, 16);
                quo_var(i) := '1';
            else
                quo_var(i) := '0';
            end if;
        end loop;

        result <= std_logic_vector(quo_var);
        odd    <= std_logic_vector(rem_var);
    end process;

end Behavioral;
