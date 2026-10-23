library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LFSR is
    Port (
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        out : out STD_LOGIC_VECTOR(3 downto 0)
    );
end LFSR;

architecture RTL of LFSR is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                out <= "0000";
            else
                out <= out(2 downto 0) & (not (out(3) xor out(2)));
            end if;
        end if;
    end process;
end RTL;
