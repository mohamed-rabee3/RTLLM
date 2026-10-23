library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity freq_divbyfrac is
    Port ( clk    : in  STD_LOGIC;
           rst_n  : in  STD_LOGIC;
           clk_div: out STD_LOGIC);
end freq_divbyfrac;

architecture Behavioral of freq_divbyfrac is
    constant MUL2_DIV_CLK : integer := 7;
    signal cnt : unsigned(2 downto 0) := (others => '0');
    signal clk_div_temp1 : std_logic := '0';
    signal clk_div_temp2 : std_logic := '0';
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= (others => '0');
        elsif rising_edge(clk) then
            if cnt = MUL2_DIV_CLK - 1 then
                cnt <= (others => '0');
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_temp1 <= '0';
        elsif rising_edge(clk) then
            if cnt = 0 or cnt = 1 then
                clk_div_temp1 <= '1';
            else
                clk_div_temp1 <= '0';
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_temp2 <= '0';
        elsif falling_edge(clk) then
            if cnt = 4 or cnt = 5 then
                clk_div_temp2 <= '1';
            else
                clk_div_temp2 <= '0';
            end if;
        end if;
    end process;

    clk_div <= clk_div_temp1 or clk_div_temp2;

end Behavioral;
