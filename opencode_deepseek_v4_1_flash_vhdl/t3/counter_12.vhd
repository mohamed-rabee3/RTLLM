library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_12 is
    Port (
        rst_n       : in  STD_LOGIC;
        clk         : in  STD_LOGIC;
        valid_count : in  STD_LOGIC;
        out         : out STD_LOGIC_VECTOR (3 downto 0)
    );
end counter_12;

architecture Behavioral of counter_12 is
    signal count : unsigned(3 downto 0) := (others => '0');
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if valid_count = '1' then
                if count = to_unsigned(11, 4) then
                    count <= (others => '0');
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    out <= std_logic_vector(count);

end Behavioral;
