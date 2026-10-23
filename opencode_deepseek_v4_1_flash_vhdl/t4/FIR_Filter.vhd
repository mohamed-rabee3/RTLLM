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
    constant C0 : signed(15 downto 0) := to_signed(64, 16);   -- 0.25 Q8.8 = 0x0040
    constant C1 : signed(15 downto 0) := to_signed(128, 16);  -- 0.5  Q8.8 = 0x0080
    constant C2 : signed(15 downto 0) := to_signed(128, 16);  -- 0.5  Q8.8 = 0x0080
    constant C3 : signed(15 downto 0) := to_signed(64, 16);   -- 0.25 Q8.8 = 0x0040

    signal d1_reg : signed(15 downto 0) := (others => '0');
    signal d2_reg : signed(15 downto 0) := (others => '0');
    signal d3_reg : signed(15 downto 0) := (others => '0');

    signal valid_out_reg : std_logic := '0';
    signal data_out_reg  : std_logic_vector(15 downto 0) := (others => '0');
begin

    process(clk)
        variable x0_v      : signed(15 downto 0);
        variable acc_v     : signed(31 downto 0);
        variable shifted_v : signed(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                d1_reg <= (others => '0');
                d2_reg <= (others => '0');
                d3_reg <= (others => '0');
                valid_out_reg <= '0';
                data_out_reg <= (others => '0');
            else
                valid_out_reg <= valid_in;

                if valid_in = '1' then
                    x0_v := signed(data_in);

                    acc_v := resize(x0_v * C0, 32) +
                             resize(d1_reg * C1, 32) +
                             resize(d2_reg * C2, 32) +
                             resize(d3_reg * C3, 32);

                    shifted_v := shift_right(acc_v, 8);
                    data_out_reg <= std_logic_vector(shifted_v(15 downto 0));

                    d3_reg <= d2_reg;
                    d2_reg <= d1_reg;
                    d1_reg <= x0_v;
                end if;
            end if;
        end if;
    end process;

    valid_out <= valid_out_reg;
    data_out  <= data_out_reg;

end rtl;
