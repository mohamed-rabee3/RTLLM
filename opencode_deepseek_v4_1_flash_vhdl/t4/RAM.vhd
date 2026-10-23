library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    Port (
        clk        : in  STD_LOGIC;
        rst_n      : in  STD_LOGIC;
        write_en   : in  STD_LOGIC;
        write_addr : in  STD_LOGIC_VECTOR (2 downto 0);
        write_data : in  STD_LOGIC_VECTOR (5 downto 0);
        read_en    : in  STD_LOGIC;
        read_addr  : in  STD_LOGIC_VECTOR (2 downto 0);
        read_data  : out STD_LOGIC_VECTOR (5 downto 0)
    );
end RAM;

architecture Behavioral of RAM is
    type ram_type is array (0 to 7) of STD_LOGIC_VECTOR(5 downto 0);
    signal RAM : ram_type := (others => (others => '0'));
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for i in RAM'range loop
                RAM(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if write_en = '1' then
                RAM(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_data <= (others => '0');
        elsif rising_edge(clk) then
            if read_en = '1' then
                read_data <= RAM(to_integer(unsigned(read_addr)));
            else
                read_data <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
