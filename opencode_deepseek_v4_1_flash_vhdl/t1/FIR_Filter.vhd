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

architecture rtl of fir_interpolator is
    constant COEFF0 : signed(15 downto 0) := to_signed(64, 16);  -- 0.25 Q8.8 = 16'sh0040
    constant COEFF1 : signed(15 downto 0) := to_signed(128, 16); -- 0.5  Q8.8 = 16'sh0080
    constant COEFF2 : signed(15 downto 0) := to_signed(128, 16); -- 0.5  Q8.8 = 16'sh0080
    constant COEFF3 : signed(15 downto 0) := to_signed(64, 16);  -- 0.25 Q8.8 = 16'sh0040

    type delay_array is array (0 to 3) of signed(15 downto 0);
    signal delay_line : delay_array := (others => (others => '0'));

    signal data_out_reg  : std_logic_vector(15 downto 0) := (others => '0');
    signal valid_out_reg : std_logic := '0';
begin

    process(clk)
        variable x0 : signed(15 downto 0);
        variable x1 : signed(15 downto 0);
        variable x2 : signed(15 downto 0);
        variable x3 : signed(15 downto 0);
        variable acc : signed(39 downto 0);
        variable shifted : signed(39 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                delay_line    <= (others => (others => '0'));
                data_out_reg  <= (others => '0');
                valid_out_reg <= '0';
            else
                valid_out_reg <= valid_in;

                if valid_in = '1' then
                    x0 := signed(data_in);
                    x1 := delay_line(0);
                    x2 := delay_line(1);
                    x3 := delay_line(2);

                    acc := resize(x0 * COEFF0, acc'length) +
                           resize(x1 * COEFF1, acc'length) +
                           resize(x2 * COEFF2, acc'length) +
                           resize(x3 * COEFF3, acc'length);

                    shifted := shift_right(acc, 8);
                    data_out_reg <= std_logic_vector(resize(shifted, 16));

                    delay_line(0) <= x0;
                    delay_line(1) <= delay_line(0);
                    delay_line(2) <= delay_line(1);
                    delay_line(3) <= delay_line(2);
                end if;
            end if;
        end if;
    end process;

    valid_out <= valid_out_reg;
    data_out <= data_out_reg;

end rtl;
