library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity freq_div is
    Port (
        CLK_in : in STD_LOGIC;
        RST    : in STD_LOGIC;
        CLK_50 : out STD_LOGIC;
        CLK_10 : out STD_LOGIC;
        CLK_1  : out STD_LOGIC
    );
end freq_div;

architecture rtl of freq_div is
    signal clk_50_int : STD_LOGIC := '0';
    signal clk_10_int : STD_LOGIC := '0';
    signal clk_1_int  : STD_LOGIC := '0';
    signal cnt_10     : integer range 0 to 4 := 0;
    signal cnt_100    : integer range 0 to 49 := 0;
begin

    CLK_50 <= clk_50_int;
    CLK_10 <= clk_10_int;
    CLK_1  <= clk_1_int;

    process(CLK_in, RST)
    begin
        if RST = '1' then
            clk_50_int <= '0';
            clk_10_int <= '0';
            cnt_10 <= 0;
            clk_1_int <= '0';
            cnt_100 <= 0;
        elsif rising_edge(CLK_in) then
            clk_50_int <= not clk_50_int;

            if cnt_10 = 4 then
                clk_10_int <= not clk_10_int;
                cnt_10 <= 0;
            else
                cnt_10 <= cnt_10 + 1;
            end if;

            if cnt_100 = 49 then
                clk_1_int <= not clk_1_int;
                cnt_100 <= 0;
            else
                cnt_100 <= cnt_100 + 1;
            end if;
        end if;
    end process;

end rtl;
