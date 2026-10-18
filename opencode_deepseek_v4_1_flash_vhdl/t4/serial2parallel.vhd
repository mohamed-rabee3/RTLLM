library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial2parallel is
    Port (
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        din_serial : in STD_LOGIC;
        din_valid : in STD_LOGIC;
        dout_parallel : out STD_LOGIC_VECTOR (7 downto 0);
        dout_valid : out STD_LOGIC
    );
end serial2parallel;

architecture Behavioral of serial2parallel is
    signal cnt : unsigned(3 downto 0) := (others => '0');
    signal dout_parallel_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal dout_valid_reg : std_logic := '0';
begin
    process(clk)
        variable idx : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt <= (others => '0');
                dout_parallel_reg <= (others => '0');
                dout_valid_reg <= '0';
            else
                if din_valid = '1' then
                    idx := 7 - to_integer(cnt);
                    dout_parallel_reg(idx) <= din_serial;
                    if cnt = 7 then
                        cnt <= (others => '0');
                        dout_valid_reg <= '1';
                    else
                        cnt <= cnt + 1;
                        dout_valid_reg <= '0';
                    end if;
                else
                    dout_valid_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    dout_parallel <= dout_parallel_reg;
    dout_valid <= dout_valid_reg;
end Behavioral;
