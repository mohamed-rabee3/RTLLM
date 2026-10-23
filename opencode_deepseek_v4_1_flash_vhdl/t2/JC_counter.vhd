library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity JC_counter is
    Port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        Q     : out STD_LOGIC_VECTOR(63 downto 0)
    );
end JC_counter;

architecture Behavioral of JC_counter is
    signal q_reg : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            q_reg <= (others => '0');
        elsif rising_edge(clk) then
            if q_reg(0) = '0' then
                q_reg <= '1' & q_reg(63 downto 1);
            else
                q_reg <= '0' & q_reg(63 downto 1);
            end if;
        end if;
    end process;

    Q <= q_reg;

end Behavioral;
