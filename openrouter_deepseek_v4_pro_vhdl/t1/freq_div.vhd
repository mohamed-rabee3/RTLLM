library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity freq_div is
    Port ( CLK_in : in  STD_LOGIC;
           RST    : in  STD_LOGIC;
           CLK_50 : out STD_LOGIC;
           CLK_10 : out STD_LOGIC;
           CLK_1  : out STD_LOGIC);
end freq_div;

architecture Behavioral of freq_div is
    signal clk50_reg : STD_LOGIC := '0';
    signal clk10_reg : STD_LOGIC := '0';
    signal clk1_reg  : STD_LOGIC := '0';
    signal cnt_10    : integer range 0 to 4 := 0;
    signal cnt_100   : integer range 0 to 49 := 0;
begin
    -- Connect internal registers to output ports
    CLK_50 <= clk50_reg;
    CLK_10 <= clk10_reg;
    CLK_1  <= clk1_reg;

    -- CLK_50 generation: divide by 2 (toggle every cycle)
    process(CLK_in, RST)
    begin
        if RST = '1' then
            clk50_reg <= '0';
        elsif rising_edge(CLK_in) then
            clk50_reg <= not clk50_reg;
        end if;
    end process;

    -- CLK_10 generation: divide by 10 (toggle when cnt_10 = 4)
    process(CLK_in, RST)
    begin
        if RST = '1' then
            clk10_reg <= '0';
            cnt_10 <= 0;
        elsif rising_edge(CLK_in) then
            if cnt_10 = 4 then
                clk10_reg <= not clk10_reg;
                cnt_10 <= 0;
            else
                cnt_10 <= cnt_10 + 1;
            end if;
        end if;
    end process;

    -- CLK_1 generation: divide by 100 (toggle when cnt_100 = 49)
    process(CLK_in, RST)
    begin
        if RST = '1' then
            clk1_reg <= '0';
            cnt_100 <= 0;
        elsif rising_edge(CLK_in) then
            if cnt_100 = 49 then
                clk1_reg <= not clk1_reg;
                cnt_100 <= 0;
            else
                cnt_100 <= cnt_100 + 1;
            end if;
        end if;
    end process;

end Behavioral;