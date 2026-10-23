library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity up_down_counter is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        up_down : in  STD_LOGIC;
        count   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end up_down_counter;

architecture RTL of up_down_counter is
    signal count_int : unsigned(15 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count_int <= (others => '0');
            else
                if up_down = '1' then
                    count_int <= count_int + 1;
                else
                    count_int <= count_int - 1;
                end if;
            end if;
        end if;
    end process;

    count <= std_logic_vector(count_int);

end RTL;
