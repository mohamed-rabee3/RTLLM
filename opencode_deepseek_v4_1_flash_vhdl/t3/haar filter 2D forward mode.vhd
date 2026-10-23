library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity haar_wavelet_lh_only is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        valid_in : in  std_logic;
        row      : in  std_logic_vector(3 downto 0);
        col      : in  std_logic_vector(3 downto 0);
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(15 downto 0);
        valid_out: out std_logic;
        out_row  : out std_logic_vector(2 downto 0);
        out_col  : out std_logic_vector(2 downto 0)
    );
end entity haar_wavelet_lh_only;

architecture rtl of haar_wavelet_lh_only is
    type image_array is array (0 to 15, 0 to 15) of unsigned(7 downto 0);
    signal image : image_array;
    type state_t is (IDLE, OUTPUT);
    signal state : state_t;
    signal out_cnt : unsigned(5 downto 0);
    constant C181 : signed(8 downto 0) := to_signed(181, 9);
begin

    process(clk, rst_n)
        variable r, c : integer range 0 to 7;
        variable row_top, row_bottom, col_left, col_right : integer range 0 to 15;
        variable p00, p01, p10, p11 : unsigned(7 downto 0);
        variable s00, s01, s10, s11 : signed(8 downto 0);
        variable diff_top, diff_bottom : signed(8 downto 0);
        variable prod_top, prod_bottom : signed(17 downto 0);
        variable hp_top, hp_bottom : signed(8 downto 0);
        variable sum_hp : signed(9 downto 0);
        variable prod_sum : signed(18 downto 0);
        variable coeff : signed(15 downto 0);
    begin
        if rst_n = '0' then
            state <= IDLE;
            out_cnt <= (others => '0');
            valid_out <= '0';
            data_out <= (others => '0');
            out_row <= (others => '0');
            out_col <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    valid_out <= '0';
                    if valid_in = '1' then
                        image(to_integer(unsigned(row)), to_integer(unsigned(col))) <= unsigned(data_in);
                        if row = "1111" and col = "1111" then
                            state <= OUTPUT;
                            out_cnt <= (others => '0');
                        end if;
                    end if;

                when OUTPUT =>
                    r := to_integer(unsigned(out_cnt(5 downto 3)));
                    c := to_integer(unsigned(out_cnt(2 downto 0)));
                    row_top := r * 2;
                    row_bottom := row_top + 1;
                    col_left := c * 2;
                    col_right := col_left + 1;

                    p00 := image(row_top, col_left);
                    p01 := image(row_top, col_right);
                    p10 := image(row_bottom, col_left);
                    p11 := image(row_bottom, col_right);

                    s00 := signed(resize(p00, 9));
                    s01 := signed(resize(p01, 9));
                    s10 := signed(resize(p10, 9));
                    s11 := signed(resize(p11, 9));

                    diff_top := s00 - s01;
                    diff_bottom := s10 - s11;

                    prod_top := diff_top * C181;
                    prod_bottom := diff_bottom * C181;

                    hp_top := resize(shift_right(prod_top, 8), 9);
                    hp_bottom := resize(shift_right(prod_bottom, 8), 9);

                    sum_hp := resize(hp_top, 10) + resize(hp_bottom, 10);

                    prod_sum := sum_hp * C181;

                    coeff := resize(shift_right(prod_sum, 8), 16);

                    data_out <= std_logic_vector(coeff);
                    out_row <= std_logic_vector(out_cnt(5 downto 3));
                    out_col <= std_logic_vector(out_cnt(2 downto 0));
                    valid_out <= '1';

                    if out_cnt = 63 then
                        state <= IDLE;
                    else
                        out_cnt <= out_cnt + 1;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;
