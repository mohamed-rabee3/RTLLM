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
    signal clk_phase_p : std_logic;
    signal clk_phase_n : std_logic;
begin

    -- Rising-edge phase: successive pulse starts are separated by
    -- four input cycles and then three input cycles.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count       <= 0;
            clk_phase_p <= '0';
        elsif rising_edge(clk) then
            if count = MUL2_DIV_CLK - 1 then
                count <= 0;
            else
                count <= count + 1;
            end if;

            case count is
                when 0 | 1 | 4 =>
                    clk_phase_p <= '1';
                when others =>
                    clk_phase_p <= '0';
            end case;
        end if;
    end process;

    -- Falling-edge phase uses the counter value already updated on
    -- the preceding rising edge. It advances the second pulse by
    -- half an input cycle and extends its falling edge by half a cycle.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            clk_phase_n <= '0';
        elsif falling_edge(clk) then
            case count is
                when 1 | 4 | 5 =>
                    clk_phase_n <= '1';
                when others =>
                    clk_phase_n <= '0';
            end case;
        end if;
    end process;

    -- Each output period is 3.5 input cycles:
    -- two cycles high followed by one and a half cycles low.
    clk_div <= clk_phase_p or clk_phase_n;

end architecture rtl;
