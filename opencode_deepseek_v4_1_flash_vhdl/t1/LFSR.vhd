library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LFSR is
    port (
        clk : in std_logic;
        rst : in std_logic;
        \out\ : out std_logic_vector(3 downto 0)
    );
end LFSR;

architecture Behavioral of LFSR is
    signal reg : std_logic_vector(3 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            else
                reg <= reg(2 downto 0) & (not (reg(3) xor reg(2)));
            end if;
        end if;
    end process;

    \out\ <= reg;
end Behavioral;
