library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ring_counter is
    Port ( clk   : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           out   : out STD_LOGIC_VECTOR(7 downto 0)
         );
end ring_counter;

architecture Behavioral of ring_counter is
    signal count_reg : STD_LOGIC_VECTOR(7 downto 0);
begin
    -- Drive the output port from the internal register
    out <= count_reg;

    process(clk, reset)
    begin
        if reset = '1' then
            -- Asynchronous reset: initialize with LSB set
            count_reg <= "00000001";
        elsif rising_edge(clk) then
            -- Rotate left: the '1' moves to the next higher bit,
            -- wrapping from MSB back to LSB.
            count_reg <= count_reg(6 downto 0) & count_reg(7);
        end if;
    end process;
end Behavioral;