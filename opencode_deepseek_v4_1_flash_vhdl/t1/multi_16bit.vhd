library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_16bit is
    Port (
        clk   : in  STD_LOGIC;
        rst_n : in  STD_LOGIC;
        start : in  STD_LOGIC;
        ain   : in  STD_LOGIC_VECTOR (15 downto 0);
        bin   : in  STD_LOGIC_VECTOR (15 downto 0);
        yout  : out STD_LOGIC_VECTOR (31 downto 0);
        done  : out STD_LOGIC
    );
end multi_16bit;

architecture Behavioral of multi_16bit is
    signal i      : integer range 0 to 17 := 0;
    signal done_r : STD_LOGIC := '0';
    signal areg   : UNSIGNED(15 downto 0) := (others => '0');
    signal breg   : UNSIGNED(15 downto 0) := (others => '0');
    signal yout_r : UNSIGNED(31 downto 0) := (others => '0');
begin

    process(clk, rst_n)
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

    process(clk, rst_n)
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

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            areg   <= (others => '0');
            breg   <= (others => '0');
            yout_r <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' then
                if i = 0 then
                    areg   <= unsigned(ain);
                    breg   <= unsigned(bin);
                    yout_r <= (others => '0');
                elsif i > 0 and i < 17 then
                    if areg(i - 1) = '1' then
                        yout_r <= yout_r + shift_left(resize(breg, 32), i - 1);
                    end if;
                end if;
            end if;
        end if;
    end process;

    yout <= std_logic_vector(yout_r);
    done <= done_r;

end Behavioral;
