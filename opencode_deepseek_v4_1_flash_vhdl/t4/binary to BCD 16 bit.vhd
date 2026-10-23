library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd_array is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        binary_in : in  std_logic_vector(15 downto 0);
        bcd_out   : out std_logic_vector(19 downto 0);
        valid_out : out std_logic
    );
end bin2bcd_array;

architecture rtl of bin2bcd_array is
begin
    process(clk)
        variable bcd : unsigned(19 downto 0);
        variable bin : unsigned(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_out   <= (others => '0');
                valid_out <= '0';
            else
                valid_out <= valid_in;
                if valid_in = '1' then
                    bcd := (others => '0');
                    bin := unsigned(binary_in);

                    for i in 0 to 15 loop
                        if bcd(3 downto 0) >= 5 then
                            bcd(3 downto 0) := bcd(3 downto 0) + 3;
                        end if;
                        if bcd(7 downto 4) >= 5 then
                            bcd(7 downto 4) := bcd(7 downto 4) + 3;
                        end if;
                        if bcd(11 downto 8) >= 5 then
                            bcd(11 downto 8) := bcd(11 downto 8) + 3;
                        end if;
                        if bcd(15 downto 12) >= 5 then
                            bcd(15 downto 12) := bcd(15 downto 12) + 3;
                        end if;
                        if bcd(19 downto 16) >= 5 then
                            bcd(19 downto 16) := bcd(19 downto 16) + 3;
                        end if;

                        bcd := bcd(18 downto 0) & bin(15);
                        bin := bin(14 downto 0) & '0';
                    end loop;

                    bcd_out <= std_logic_vector(bcd);
                end if;
            end if;
        end if;
    end process;
end rtl;
