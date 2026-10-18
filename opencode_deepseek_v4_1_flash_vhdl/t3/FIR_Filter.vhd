library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        valid_in  : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR (15 downto 0);
        valid_out : out STD_LOGIC;
        data_out  : out STD_LOGIC_VECTOR (15 downto 0)
    );
end fir_interpolator;

architecture RTL of fir_interpolator is
    constant C_H0 : signed(15 downto 0) := to_signed(64, 16);
    constant C_H1 : signed(15 downto 0) := to_signed(128, 16);
    constant C_H2 : signed(15 downto 0) := to_signed(128, 16);
    constant C_H3 : signed(15 downto 0) := to_signed(64, 16);

    signal x1 : signed(15 downto 0) := (others => '0');
    signal x2 : signed(15 downto 0) := (others => '0');
    signal x3 : signed(15 downto 0) := (others => '0');
begin

    process(clk)
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
                valid_out <= valid_in;

                if valid_in = '1' then
                    acc := signed(data_in) * C_H0;
                    acc := acc + x1 * C_H1;
                    acc := acc + x2 * C_H2;
                    acc := acc + x3 * C_H3;

                    shifted := shift_right(acc, 8);
                    data_out <= std_logic_vector(shifted(15 downto 0));

                    x3 <= x2;
                    x2 <= x1;
                    x1 <= signed(data_in);
                end if;
            end if;
        end if;
    end process;

end RTL;
