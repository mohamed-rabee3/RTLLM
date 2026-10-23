library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_divbyfrac is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        clk_div : out std_logic
    );
end entity freq_divbyfrac;

architecture rtl of freq_divbyfrac is
    constant MUL2_DIV_CLK : positive := 7;

    signal count         : unsigned(2 downto 0);
    signal clk_div_pos   : std_logic;
    signal clk_div_neg   : std_logic;
begin

    -- Rising-edge pulses are alternately four and three input cycles apart.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count       <= (others => '0');
            clk_div_pos <= '0';
        elsif rising_edge(clk) then
            if count = to_unsigned(MUL2_DIV_CLK - 1, count'length) then
                count <= (others => '0');
            else
                count <= count + 1;
            end if;

            if (count = to_unsigned(0, count'length)) or
               (count = to_unsigned(4, count'length)) then
                clk_div_pos <= '1';
            else
                clk_div_pos <= '0';
            end if;
        end if;
    end process;

    -- The counter has already advanced at the preceding rising edge.
    -- The first pulse is delayed by half a cycle; the second is advanced
    -- by half a cycle relative to its corresponding rising-edge pulse.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            clk_div_neg <= '0';
        elsif falling_edge(clk) then
            if (count = to_unsigned(1, count'length)) or
               (count = to_unsigned(4, count'length)) then
                clk_div_neg <= '1';
            else
                clk_div_neg <= '0';
            end if;
        end if;
    end process;

    -- Uniform 3.5-cycle period: 1.5 cycles high and 2 cycles low.
    clk_div <= clk_div_pos or clk_div_neg;

end architecture rtl;
