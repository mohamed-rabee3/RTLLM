library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(15 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end fir_interpolator;

architecture rtl of fir_interpolator is
    signal x1 : signed(15 downto 0) := (others => '0');
    signal x2 : signed(15 downto 0) := (others => '0');
    signal x3 : signed(15 downto 0) := (others => '0');

    constant H0 : signed(15 downto 0) := to_signed(64, 16);
    constant H1 : signed(15 downto 0) := to_signed(128, 16);
    constant H2 : signed(15 downto 0) := to_signed(128, 16);
    constant H3 : signed(15 downto 0) := to_signed(64, 16);
begin
    process(clk)
        variable data_s  : signed(15 downto 0);
        variable acc     : signed(31 downto 0);
        variable shifted : signed(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                x1 <= (others => '0');
                x2 <= (others => '0');
                x3 <= (others => '0');
                valid_out <= '0';
                data_out <= (others => '0');
            else
                valid_out <= '0';
                if valid_in = '1' then
                    data_s := signed(data_in);
                    acc := (H0 * data_s) + (H1 * x1) + (H2 * x2) + (H3 * x3);
                    shifted := shift_right(acc, 8);
                    data_out <= std_logic_vector(shifted(15 downto 0));
                    valid_out <= '1';
                    x3 <= x2;
                    x2 <= x1;
                    x1 <= data_s;
                end if;
            end if;
        end if;
    end process;
end rtl;
