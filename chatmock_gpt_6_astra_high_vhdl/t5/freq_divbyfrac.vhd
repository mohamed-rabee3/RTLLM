library ieee;
use ieee.std_logic_1164.all;

entity freq_divbyfrac is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end entity freq_divbyfrac;

architecture rtl of freq_divbyfrac is
    constant MUL2_DIV_CLK : positive := 7;

    signal count     : integer range 0 to MUL2_DIV_CLK - 1;
    signal clk_pos   : std_logic;
    signal clk_neg   : std_logic;
begin

    -- Rising-edge waveform: alternating four- and three-cycle periods.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count   <= 0;
            clk_pos <= '0';
        elsif rising_edge(clk) then
            if count = MUL2_DIV_CLK - 1 then
                count <= 0;
            else
                count <= count + 1;
            end if;

            if (count = 0) or (count = 1) or (count = 4) then
                clk_pos <= '1';
            else
                clk_pos <= '0';
            end if;
        end if;
    end process;

    -- The counter has already advanced at the preceding rising edge.
    -- This pulse advances the second rising edge by half a source cycle
    -- and delays its falling edge by half a source cycle.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            clk_neg <= '0';
        elsif falling_edge(clk) then
            if (count = 4) or (count = 5) then
                clk_neg <= '1';
            else
                clk_neg <= '0';
            end if;
        end if;
    end process;

    -- Uniform 3.5-cycle period: two cycles high, 1.5 cycles low.
    clk_div <= clk_pos or clk_neg;

end architecture rtl;
