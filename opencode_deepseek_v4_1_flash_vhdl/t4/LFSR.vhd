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
    signal r_out : STD_LOGIC_VECTOR(3 downto 0);
    signal feedback : STD_LOGIC;
begin
    feedback <= not (r_out(3) xor r_out(2));

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_out <= (others => '0');
            else
                r_out <= r_out(2 downto 0) & feedback;
            end if;
        end if;
    end process;

    \out\ <= r_out;
end Behavioral;
