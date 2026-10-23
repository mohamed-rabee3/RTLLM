library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd_array is
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        binary_in : in  STD_LOGIC_VECTOR(15 downto 0);
        bcd_out   : out STD_LOGIC_VECTOR(19 downto 0);
        valid_out : out STD_LOGIC
    );
end bin2bcd_array;

architecture Behavioral of bin2bcd_array is
begin
    process(clk)
        variable tmp : unsigned(35 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                bcd_out <= (others => '0');
                valid_out <= '0';
            else
                valid_out <= '0';
                if valid_in = '1' then
                    tmp := (others => '0');
                    tmp(15 downto 0) := unsigned(binary_in);
                    for i in 0 to 15 loop
                        -- Add 3 to each BCD digit if it is 5 or greater
                        if tmp(19 downto 16) >= 5 then
                            tmp(19 downto 16) := tmp(19 downto 16) + 3;
                        end if;
                        if tmp(23 downto 20) >= 5 then
                            tmp(23 downto 20) := tmp(23 downto 20) + 3;
                        end if;
                        if tmp(27 downto 24) >= 5 then
                            tmp(27 downto 24) := tmp(27 downto 24) + 3;
                        end if;
                        if tmp(31 downto 28) >= 5 then
                            tmp(31 downto 28) := tmp(31 downto 28) + 3;
                        end if;
                        if tmp(35 downto 32) >= 5 then
                            tmp(35 downto 32) := tmp(35 downto 32) + 3;
                        end if;
                        -- Shift left by one bit
                        tmp := tmp(34 downto 0) & '0';
                    end loop;
                    bcd_out <= std_logic_vector(tmp(35 downto 16));
                    valid_out <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
