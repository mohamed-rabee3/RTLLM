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
end entity bin2bcd_array;

architecture rtl of bin2bcd_array is

    function bin_to_bcd(bin : unsigned(15 downto 0)) return unsigned is
        variable bcd     : unsigned(19 downto 0) := (others => '0');
        variable bin_reg : unsigned(15 downto 0) := bin;
    begin
        for i in 0 to 15 loop
            for j in 0 to 4 loop
                if bcd(4*j+3 downto 4*j) >= 5 then
                    bcd(4*j+3 downto 4*j) := bcd(4*j+3 downto 4*j) + 3;
                end if;
            end loop;
            bcd     := bcd(18 downto 0) & bin_reg(15);
            bin_reg := bin_reg(14 downto 0) & '0';
        end loop;
        return bcd;
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_out   <= (others => '0');
                valid_out <= '0';
            else
                valid_out <= valid_in;
                if valid_in = '1' then
                    bcd_out <= std_logic_vector(bin_to_bcd(unsigned(binary_in)));
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
