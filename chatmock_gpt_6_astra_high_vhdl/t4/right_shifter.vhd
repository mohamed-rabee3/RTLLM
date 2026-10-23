library ieee;
use ieee.std_logic_1164.all;

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
    q <= q_reg;

    process (clk)
    begin
        if rising_edge(clk) then
            q_reg <= d & q_reg(7 downto 1);
        end if;
    end process;
end architecture rtl;
