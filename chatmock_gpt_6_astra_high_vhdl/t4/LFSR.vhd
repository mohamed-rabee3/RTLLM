library ieee;
use ieee.std_logic_1164.all;

entity LFSR is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        \out\ : out std_logic_vector(3 downto 0)
    );
end entity LFSR;

architecture rtl of LFSR is
    signal state : std_logic_vector(3 downto 0);
begin
    \out\ <= state;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= (others => '0');
            else
                state <= state(2 downto 0) & (not (state(3) xor state(2)));
            end if;
        end if;
    end process;
end architecture rtl;
