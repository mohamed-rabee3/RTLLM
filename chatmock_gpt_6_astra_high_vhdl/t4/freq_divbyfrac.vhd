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

    signal count     : unsigned(2 downto 0);
    signal phase_pos : std_logic;
    signal phase_neg : std_logic;
begin

    -- Seven source-clock cycles contain two output-clock periods.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            count     <= (others => '0');
            phase_pos <= '0';
        elsif rising_edge(clk) then
            if count = to_unsigned(MUL2_DIV_CLK - 1, count'length) then
                count <= (others => '0');
            else
                count <= count + 1;
            end if;

            -- First pulse: two complete source-clock cycles wide.
            if count = to_unsigned(0, count'length) then
                phase_pos <= '1';
            elsif count = to_unsigned(2, count'length) then
                phase_pos <= '0';
            end if;
        end if;
    end process;

    -- The falling-edge process observes the updated counter. Thus its
    -- pulse starts half a cycle before the rising edge that sees count=4,
    -- correcting the otherwise alternating four-/three-cycle spacing.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            phase_neg <= '0';
        elsif falling_edge(clk) then
            if count = to_unsigned(4, count'length) then
                phase_neg <= '1';
            elsif count = to_unsigned(6, count'length) then
                phase_neg <= '0';
            end if;
        end if;
    end process;

    -- Uniform 3.5-cycle period: two cycles high and 1.5 cycles low.
    clk_div <= phase_pos or phase_neg;

end architecture rtl;
