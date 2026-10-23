library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity right_shifter is
    Port (
        clk : in  STD_LOGIC;
        d   : in  STD_LOGIC;
        q   : out STD_LOGIC_VECTOR (7 downto 0)
    );
end right_shifter;

architecture Behavioral of right_shifter is
    signal q_reg : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            q_reg <= d & q_reg(7 downto 1);
        end if;
    end process;

    q <= q_reg;
end Behavioral;
