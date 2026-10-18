library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity JC_counter is
    Port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        Q     : out STD_LOGIC_VECTOR(63 downto 0)
    );
end JC_counter;

architecture RTL of JC_counter is
    signal Q_reg : STD_LOGIC_VECTOR(63 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            Q_reg <= (others => '0');
        elsif rising_edge(clk) then
            if Q_reg(0) = '0' then
                Q_reg <= '1' & Q_reg(63 downto 1);
            else
                Q_reg <= '0' & Q_reg(63 downto 1);
            end if;
        end if;
    end process;

    Q <= Q_reg;

end RTL;
