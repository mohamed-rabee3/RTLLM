library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LFSR is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        \out\ : out STD_LOGIC_VECTOR(3 downto 0)
    );
end LFSR;

architecture Behavioral of LFSR is
    signal reg : STD_LOGIC_VECTOR(3 downto 0);
    signal feedback : STD_LOGIC;
begin
    feedback <= not (reg(3) xor reg(2));

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (others => '0');
            else
                reg <= reg(2 downto 0) & feedback;
            end if;
        end if;
    end process;

    \out\ <= reg;
end Behavioral;
