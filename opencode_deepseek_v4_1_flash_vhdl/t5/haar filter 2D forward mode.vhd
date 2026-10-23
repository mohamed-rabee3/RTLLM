library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity haar_wavelet_lh_only is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           valid_in : in STD_LOGIC;
           row : in STD_LOGIC_VECTOR (3 downto 0);
           col : in STD_LOGIC_VECTOR (3 downto 0);
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (15 downto 0);
           valid_out : out STD_LOGIC;
           out_row : out STD_LOGIC_VECTOR (2 downto 0);
           out_col : out STD_LOGIC_VECTOR (2 downto 0));
end haar_wavelet_lh_only;

architecture rtl of haar_wavelet_lh_only is
    type mem_t is array (0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
    signal mem : mem_t;
    type state_t is (IDLE, WRITE, OUTPUT);
    signal state : state_t;
    signal out_row_reg : integer range 0 to 7;
    signal out_col_reg : integer range 0 to 7;
    signal coeff_cnt : integer range 0 to 63;
    constant SCALE : signed(8 downto 0) := to_signed(181, 9);
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            out_row_reg <= 0;
            out_col_reg <= 0;
            coeff_cnt <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if valid_in = '1' then
                        mem(to_integer(unsigned(row)), to_integer(unsigned(col))) <= data_in;
                        if row = "1111" and col = "1111" then
                            state <= OUTPUT;
                            out_row_reg <= 0;
                            out_col_reg <= 0;
                            coeff_cnt <= 0;
                        else
                            state <= WRITE;
                        end if;
                    end if;
                when WRITE =>
                    if valid_in = '1' then
                        mem(to_integer(unsigned(row)), to_integer(unsigned(col))) <= data_in;
                        if row = "1111" and col = "1111" then
                            state <= OUTPUT;
                            out_row_reg <= 0;
                            out_col_reg <= 0;
                            coeff_cnt <= 0;
                        end if;
                    end if;
                when OUTPUT =>
                    if coeff_cnt = 63 then
                        state <= IDLE;
                    else
                        coeff_cnt <= coeff_cnt + 1;
                        if out_col_reg = 7 then
                            out_col_reg <= 0;
                            if out_row_reg = 7 then
                                out_row_reg <= 0;
                            else
                                out_row_reg <= out_row_reg + 1;
                            end if;
                        else
                            out_col_reg <= out_col_reg + 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;

    valid_out <= '1' when state = OUTPUT else '0';
    out_row <= std_logic_vector(to_unsigned(out_row_reg, 3));
    out_col <= std_logic_vector(to_unsigned(out_col_reg, 3));

    process(state, out_row_reg, out_col_reg, mem)
        variable r, c : integer range 0 to 7;
        variable re, ro, ce, co : integer range 0 to 15;
        variable p00, p01, p10, p11 : unsigned(7 downto 0);
        variable diff_top, diff_bot : signed(8 downto 0);
        variable prod_top, prod_bot : signed(17 downto 0);
        variable h_top, h_bot : signed(8 downto 0);
        variable sum_h : signed(9 downto 0);
        variable prod_sum : signed(18 downto 0);
        variable res : signed(8 downto 0);
        variable res16 : signed(15 downto 0);
    begin
        data_out <= (others => '0');
        if state = OUTPUT then
            r := out_row_reg;
            c := out_col_reg;
            re := 2 * r;
            ro := re + 1;
            ce := 2 * c;
            co := ce + 1;

            p00 := unsigned(mem(re, ce));
            p01 := unsigned(mem(re, co));
            p10 := unsigned(mem(ro, ce));
            p11 := unsigned(mem(ro, co));

            diff_top := signed(resize(p00, 9)) - signed(resize(p01, 9));
            diff_bot := signed(resize(p10, 9)) - signed(resize(p11, 9));

            prod_top := diff_top * SCALE;
            prod_bot := diff_bot * SCALE;

            h_top := resize(shift_right(prod_top, 8), 9);
            h_bot := resize(shift_right(prod_bot, 8), 9);

            sum_h := resize(h_top, 10) + resize(h_bot, 10);

            prod_sum := sum_h * SCALE;

            res := resize(shift_right(prod_sum, 8), 9);
            res16 := resize(res, 16);
            data_out <= std_logic_vector(res16);
        end if;
    end process;
end rtl;
