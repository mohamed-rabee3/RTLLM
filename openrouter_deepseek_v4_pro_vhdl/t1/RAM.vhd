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
        write_addr : in  std_logic_vector(WIDTH-1 downto 0);
        write_data : in  std_logic_vector(DEPTH-1 downto 0);
        read_en    : in  std_logic;
        read_addr  : in  std_logic_vector(WIDTH-1 downto 0);
        read_data  : out std_logic_vector(DEPTH-1 downto 0)
    );
end entity RAM;

architecture behavioral of RAM is

    -- Define the RAM array type: 2^WIDTH locations, each DEPTH bits wide
    type ram_type is array (0 to (2**WIDTH)-1) of std_logic_vector(DEPTH-1 downto 0);
    
    -- RAM array signal initialized to all zeros
    signal ram_array : ram_type := (others => (others => '0'));
    
    -- Internal read data register
    signal read_data_reg : std_logic_vector(DEPTH-1 downto 0) := (others => '0');

begin

    -- Write Operation Process
    write_process : process(clk, rst_n)
    begin
        if (rst_n = '0') then
            -- Active-low reset: clear all memory locations to 0
            ram_array <= (others => (others => '0'));
        elsif (rising_edge(clk)) then
            if (write_en = '1') then
                -- Write data to the specified address
                ram_array(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process write_process;

    -- Read Operation Process
    read_process : process(clk, rst_n)
    begin
        if (rst_n = '0') then
            -- Active-low reset: clear read data register
            read_data_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (read_en = '1') then
                -- Read data from the specified address
                read_data_reg <= ram_array(to_integer(unsigned(read_addr)));
            else
                -- Clear read data register when read_en is not active
                read_data_reg <= (others => '0');
            end if;
        end if;
    end process read_process;

    -- Assign internal read data register to output port
    read_data <= read_data_reg;

end architecture behavioral;