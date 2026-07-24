library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_bin2bcd_array is
    port(clk       : in  std_logic;
         rst       : in  std_logic;
         valid_in  : in  std_logic;
         binary_in : in  std_logic_vector(15 downto 0);
         bcd_out   : out std_logic_vector(19 downto 0);
         valid_out : out std_logic);
end verified_bin2bcd_array;
architecture rtl of verified_bin2bcd_array is
    function to_bcd(bin : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable sh : unsigned(35 downto 0);
    begin
        sh := (others => '0');
        sh(15 downto 0) := unsigned(bin);
        for i in 0 to 15 loop
            if sh(19 downto 16) >= 5 then sh(19 downto 16) := sh(19 downto 16) + 3; end if;
            if sh(23 downto 20) >= 5 then sh(23 downto 20) := sh(23 downto 20) + 3; end if;
            if sh(27 downto 24) >= 5 then sh(27 downto 24) := sh(27 downto 24) + 3; end if;
            if sh(31 downto 28) >= 5 then sh(31 downto 28) := sh(31 downto 28) + 3; end if;
            if sh(35 downto 32) >= 5 then sh(35 downto 32) := sh(35 downto 32) + 3; end if;
            sh := sh sll 1;
        end loop;
        return std_logic_vector(sh(35 downto 16));
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
                    bcd_out <= to_bcd(binary_in);
                end if;
            end if;
        end if;
    end process;
end rtl;
