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
end entity fir_interpolator;

architecture rtl of fir_interpolator is
    constant H0 : signed(15 downto 0) := to_signed(16#0040#, 16);
    constant H1 : signed(15 downto 0) := to_signed(16#0080#, 16);
    constant H2 : signed(15 downto 0) := to_signed(16#0080#, 16);
    constant H3 : signed(15 downto 0) := to_signed(16#0040#, 16);

    constant ACC_WIDTH : integer := 32;

    signal x1 : signed(15 downto 0) := (others => '0');
    signal x2 : signed(15 downto 0) := (others => '0');
    signal x3 : signed(15 downto 0) := (others => '0');

    signal data_out_reg  : std_logic_vector(15 downto 0) := (others => '0');
    signal valid_out_reg : std_logic := '0';
begin
    process(clk)
        variable acc : signed(ACC_WIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                x1 <= (others => '0');
                x2 <= (others => '0');
                x3 <= (others => '0');
                data_out_reg  <= (others => '0');
                valid_out_reg <= '0';
            else
                valid_out_reg <= valid_in;

                if valid_in = '1' then
                    acc := resize(H0 * signed(data_in), ACC_WIDTH) +
                           resize(H1 * x1, ACC_WIDTH) +
                           resize(H2 * x2, ACC_WIDTH) +
                           resize(H3 * x3, ACC_WIDTH);

                    data_out_reg <= std_logic_vector(acc(23 downto 8));

                    x3 <= x2;
                    x2 <= x1;
                    x1 <= signed(data_in);
                end if;
            end if;
        end if;
    end process;

    data_out  <= data_out_reg;
    valid_out <= valid_out_reg;
end architecture rtl;
