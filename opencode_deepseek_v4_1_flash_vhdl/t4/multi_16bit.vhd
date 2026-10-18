library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_16bit is
    Port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        start : in  std_logic;
        ain   : in  std_logic_vector(15 downto 0);
        bin   : in  std_logic_vector(15 downto 0);
        yout  : out std_logic_vector(31 downto 0);
        done  : out std_logic
    );
end multi_16bit;

architecture rtl of multi_16bit is
    signal i      : integer range 0 to 17 := 0;
    signal done_r : std_logic := '0';
    signal areg   : unsigned(15 downto 0) := (others => '0');
    signal breg   : unsigned(15 downto 0) := (others => '0');
    signal yout_r : unsigned(31 downto 0) := (others => '0');
begin

    process(clk, rst_n)
        variable shift_amount : natural range 0 to 15;
    begin
        if rst_n = '0' then
            i      <= 0;
            done_r <= '0';
            areg   <= (others => '0');
            breg   <= (others => '0');
            yout_r <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' then
                if i < 17 then
                    i <= i + 1;
                end if;
            else
                i <= 0;
            end if;

            if i = 16 then
                done_r <= '1';
            elsif i = 17 then
                done_r <= '0';
            end if;

            if start = '1' then
                if i = 0 then
                    areg   <= unsigned(ain);
                    breg   <= unsigned(bin);
                    yout_r <= (others => '0');
                elsif i > 0 and i < 17 then
                    if areg(i - 1) = '1' then
                        shift_amount := i - 1;
                        yout_r <= yout_r + shift_left(resize(breg, 32), shift_amount);
                    end if;
                end if;
            end if;
        end if;
    end process;

    yout <= std_logic_vector(yout_r);
    done <= done_r;

end rtl;
