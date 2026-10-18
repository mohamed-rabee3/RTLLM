library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity freq_divbyfrac is
    Port ( clk     : in  STD_LOGIC;
           rst_n   : in  STD_LOGIC;
           clk_div : out STD_LOGIC
         );
end freq_divbyfrac;

architecture Behavioral of freq_divbyfrac is
    constant MUL2_DIV_CLK : integer := 7;
    signal cnt      : unsigned(2 downto 0);
    signal clk_div1 : STD_LOGIC;
    signal clk_div2 : STD_LOGIC;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt      <= (others => '0');
            clk_div1 <= '0';
        elsif rising_edge(clk) then
            if cnt = to_unsigned(MUL2_DIV_CLK - 1, cnt'length) then
                cnt      <= (others => '0');
                clk_div1 <= not clk_div1;
            else
                cnt <= cnt + 1;
                if cnt = to_unsigned(MUL2_DIV_CLK / 2, cnt'length) then
                    clk_div1 <= not clk_div1;
                end if;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div2 <= '0';
        elsif falling_edge(clk) then
            clk_div2 <= clk_div1;
        end if;
    end process;

    clk_div <= clk_div1 or clk_div2;

end Behavioral;
