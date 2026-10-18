library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity right_shifter is
    port (
        clk : in  std_logic;
        d   : in  std_logic;
        q   : out std_logic_vector(7 downto 0)
    );
end entity right_shifter;

architecture rtl of right_shifter is
    signal q_reg : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            q_reg <= d & q_reg(7 downto 1);
        end if;
    end process;

    q <= q_reg;
end architecture rtl;
