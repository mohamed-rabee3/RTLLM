library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity haar_wavelet_lh_only is
    Port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        valid_in  : in  std_logic;
        row       : in  std_logic_vector(3 downto 0);
        col       : in  std_logic_vector(3 downto 0);
        data_in   : in  std_logic_vector(7 downto 0);
        data_out  : out std_logic_vector(15 downto 0);
        valid_out : out std_logic;
        out_row   : out std_logic_vector(2 downto 0);
        out_col   : out std_logic_vector(2 downto 0)
    );
end haar_wavelet_lh_only;

architecture rtl of haar_wavelet_lh_only is
    type state_t is (IDLE, STREAM);
    signal state : state_t;

    signal count : unsigned(5 downto 0);

    type row_t is array (0 to 15) of std_logic_vector(7 downto 0);
    type img_t is array (0 to 15) of row_t;
    signal img : img_t;

    signal lh_val : signed(15 downto 0);
begin
    data_out  <= std_logic_vector(lh_val);
    valid_out <= '1' when state = STREAM else '0';
    out_row   <= std_logic_vector(count(5 downto 3));
    out_col   <= std_logic_vector(count(2 downto 0));

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            count <= (others => '0');
            for i in 0 to 15 loop
                for j in 0 to 15 loop
                    img(i)(j) <= (others => '0');
                end loop;
            end loop;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if valid_in = '1' then
                        img(to_integer(unsigned(row)))(to_integer(unsigned(col))) <= data_in;
                        if unsigned(row) = 15 and unsigned(col) = 15 then
                            state <= STREAM;
                            count <= (others => '0');
                        end if;
                    end if;

                when STREAM =>
                    if count = 63 then
                        state <= IDLE;
                        count <= (others => '0');
                    else
                        count <= count + 1;
                    end if;
            end case;
        end if;
    end process;

    process(count, img)
        variable r_v : integer range 0 to 7;
        variable c_v : integer range 0 to 7;
        variable top_e : signed(9 downto 0);
        variable top_o : signed(9 downto 0);
        variable bot_e : signed(9 downto 0);
        variable bot_o : signed(9 downto 0);
        variable diff_top : signed(9 downto 0);
        variable diff_bot : signed(9 downto 0);
        variable prod_top : signed(18 downto 0);
        variable prod_bot : signed(18 downto 0);
        variable h_top : signed(9 downto 0);
        variable h_bot : signed(9 downto 0);
        variable sum_h : signed(10 downto 0);
        variable prod_sum : signed(19 downto 0);
    begin
        r_v := to_integer(count(5 downto 3));
        c_v := to_integer(count(2 downto 0));

        top_e := signed(resize(unsigned(img(2*r_v)(2*c_v)), 10));
        top_o := signed(resize(unsigned(img(2*r_v)((2*c_v)+1)), 10));
        bot_e := signed(resize(unsigned(img((2*r_v)+1)(2*c_v)), 10));
        bot_o := signed(resize(unsigned(img((2*r_v)+1)((2*c_v)+1)), 10));

        diff_top := top_e - top_o;
        diff_bot := bot_e - bot_o;

        prod_top := diff_top * to_signed(181, 9);
        prod_bot := diff_bot * to_signed(181, 9);

        h_top := resize(shift_right(prod_top, 8), 10);
        h_bot := resize(shift_right(prod_bot, 8), 10);

        sum_h := resize(h_top, 11) + resize(h_bot, 11);
        prod_sum := sum_h * to_signed(181, 9);

        lh_val <= resize(shift_right(prod_sum, 8), 16);
    end process;
end rtl;
