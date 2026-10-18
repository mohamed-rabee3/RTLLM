library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd_array is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        binary_in : in  std_logic_vector(15 downto 0);
        bcd_out   : out std_logic_vector(19 downto 0);
        valid_out : out std_logic
    );
end bin2bcd_array;

architecture rtl of bin2bcd_array is
    function bin_to_bcd(bin : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable temp : unsigned(35 downto 0);
        variable d0, d1, d2, d3, d4 : unsigned(3 downto 0);
    begin
        temp := (others => '0');
        temp(15 downto 0) := unsigned(bin);
        for i in 0 to 15 loop
            d0 := temp(19 downto 16);
            if d0 >= 5 then
                temp(19 downto 16) := d0 + 3;
            end if;
            d1 := temp(23 downto 20);
            if d1 >= 5 then
                temp(23 downto 20) := d1 + 3;
            end if;
            d2 := temp(27 downto 24);
            if d2 >= 5 then
                temp(27 downto 24) := d2 + 3;
            end if;
            d3 := temp(31 downto 28);
            if d3 >= 5 then
                temp(31 downto 28) := d3 + 3;
            end if;
            d4 := temp(35 downto 32);
            if d4 >= 5 then
                temp(35 downto 32) := d4 + 3;
            end if;
            temp := shift_left(temp, 1);
        end loop;
        return std_logic_vector(temp(35 downto 32)) &
               std_logic_vector(temp(31 downto 28)) &
               std_logic_vector(temp(27 downto 24)) &
               std_logic_vector(temp(23 downto 20)) &
               std_logic_vector(temp(19 downto 16));
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_out <= (others => '0');
                valid_out <= '0';
            else
                if valid_in = '1' then
                    bcd_out <= bin_to_bcd(binary_in);
                    valid_out <= '1';
                else
                    valid_out <= '0';
                end if;
            end if;
        end if;
    end process;
end rtl;
