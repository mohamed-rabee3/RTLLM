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

    signal count       : natural range 0 to MUL2_DIV_CLK - 1;
    signal phase_pos   : std_logic;
    signal phase_neg   : std_logic;
begin

    -- Generate the first two-clock-wide pulse in each seven-clock frame.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count     <= 0;
            phase_pos <= '0';
        elsif rising_edge(clk) then
            if count = MUL2_DIV_CLK - 1 then
                count <= 0;
            else
                count <= count + 1;
            end if;

            if count = 0 or count = 1 then
                phase_pos <= '1';
            else
                phase_pos <= '0';
            end if;
        end if;
    end process;

    -- The falling-edge process observes the already incremented count.
    -- Its pulse starts 3.5 input periods after the positive-edge pulse
    -- and also lasts two input periods.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            phase_neg <= '0';
        elsif falling_edge(clk) then
            if count = 4 or count = 5 then
                phase_neg <= '1';
            else
                phase_neg <= '0';
            end if;
        end if;
    end process;

    -- Uniform output period: 3.5 input periods.
    -- High time: 2 input periods; low time: 1.5 input periods.
    clk_div <= phase_pos or phase_neg;

end architecture rtl;
