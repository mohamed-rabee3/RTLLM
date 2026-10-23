library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    generic (
        WIDTH : integer := 6;
        DEPTH : integer := 8
    );
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        write_en   : in  std_logic;
        write_addr : in  std_logic_vector(2 downto 0);
        write_data : in  std_logic_vector(WIDTH-1 downto 0);
        read_en    : in  std_logic;
        read_addr  : in  std_logic_vector(2 downto 0);
        read_data  : out std_logic_vector(WIDTH-1 downto 0)
    );
end RAM;

architecture rtl of RAM is
    type ram_type is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal ram : ram_type := (others => (others => '0'));
begin

    write_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            ram <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if write_en = '1' then
                ram(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    read_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            read_data <= (others => '0');
        elsif rising_edge(clk) then
            if read_en = '1' then
                read_data <= ram(to_integer(unsigned(read_addr)));
            else
                read_data <= (others => '0');
            end if;
        end if;
    end process;

end rtl;
