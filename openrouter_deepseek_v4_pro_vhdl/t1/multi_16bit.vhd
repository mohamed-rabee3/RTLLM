library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_16bit is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        start : in  std_logic;
        ain   : in  std_logic_vector(15 downto 0);
        bin   : in  std_logic_vector(15 downto 0);
        yout  : out std_logic_vector(31 downto 0);
        done  : out std_logic
    );
end entity multi_16bit;

architecture rtl of multi_16bit is

    -- Internal registers
    signal areg   : std_logic_vector(15 downto 0);
    signal breg   : std_logic_vector(15 downto 0);
    signal yout_r : unsigned(31 downto 0);
    signal done_r : std_logic;
    signal i      : integer range 0 to 17;

begin

    -- Shift count register update
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            i <= 0;
        elsif rising_edge(clk) then
            if start = '1' then
                if i < 17 then
                    i <= i + 1;
                end if;
            else
                i <= 0;
            end if;
        end if;
    end process;

    -- Done flag generation
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            done_r <= '0';
        elsif rising_edge(clk) then
            if i = 16 then
                done_r <= '1';
            elsif i = 17 then
                done_r <= '0';
            end if;
        end if;
    end process;

    -- Shift and accumulate operation
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            areg   <= (others => '0');
            breg   <= (others => '0');
            yout_r <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' then
                if i = 0 then
                    -- Load operands
                    areg   <= ain;
                    breg   <= bin;
                    yout_r <= (others => '0');
                elsif i > 0 and i < 17 then
                    -- Check bit i-1 of areg
                    if areg(i-1) = '1' then
                        -- Accumulate breg shifted left by (i-1)
                        yout_r <= yout_r + (resize(unsigned(breg), 32) sll (i-1));
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    yout <= std_logic_vector(yout_r);
    done <= done_r;

end architecture rtl;