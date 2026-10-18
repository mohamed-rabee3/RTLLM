library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic (
        WIDTH : positive := 6;
        DEPTH : positive := 8
    );
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        write_en   : in  std_logic;
        write_addr : in  std_logic_vector(WIDTH - 1 downto 0);
        write_data : in  std_logic_vector(DEPTH - 1 downto 0);
        read_en    : in  std_logic;
        read_addr  : in  std_logic_vector(WIDTH - 1 downto 0);
        read_data  : out std_logic_vector(DEPTH - 1 downto 0)
    );
end entity RAM;

architecture rtl of RAM is
    type memory_type is array (0 to (2 ** WIDTH) - 1) of
        std_logic_vector(DEPTH - 1 downto 0);

    signal memory : memory_type := (others => (others => '0'));
begin
    write_process : process (clk, rst_n)
    begin
        if rst_n = '0' then
            memory <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if write_en = '1' then
                memory(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process write_process;

    read_process : process (clk, rst_n)
    begin
        if rst_n = '0' then
            read_data <= (others => '0');
        elsif rising_edge(clk) then
            if read_en = '1' then
                read_data <= memory(to_integer(unsigned(read_addr)));
            else
                read_data <= (others => '0');
            end if;
        end if;
    end process read_process;
end architecture rtl;
