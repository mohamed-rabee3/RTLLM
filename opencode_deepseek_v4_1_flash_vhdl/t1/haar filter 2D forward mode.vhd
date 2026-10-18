library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity haar_wavelet_lh_only is
    Port (
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
end haar_wavelet_lh_only;

architecture rtl of haar_wavelet_lh_only is
    type image_type is array (0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
    signal image : image_type;

    type state_t is (IDLE, OUTPUT);
    signal state : state_t;
    signal out_idx : integer range 0 to 63;

    function scale_181_256(val : integer) return integer is
        variable prod : integer;
        variable q : integer;
    begin
        if val >= 0 then
            prod := val * 181;
            return prod / 256;
        else
            prod := (-val) * 181;
            q := prod / 256;
            return -q;
        end if;
    end function;
begin
    process(clk, rst_n)
        variable row_i, col_i : integer range 0 to 15;
        variable r_i, c_i : integer range 0 to 7;
        variable p00, p01, p10, p11 : integer range 0 to 255;
        variable hp_top, hp_bot : integer range -180 to 180;
        variable lh_val : integer range -254 to 254;
    begin
        if rst_n = '0' then
            state <= IDLE;
            out_idx <= 0;
            data_out <= (others => '0');
            valid_out <= '0';
            out_row <= (others => '0');
            out_col <= (others => '0');
        elsif rising_edge(clk) then
            valid_out <= '0';

            if state = IDLE then
                if valid_in = '1' then
                    row_i := to_integer(unsigned(row));
                    col_i := to_integer(unsigned(col));
                    image(row_i, col_i) <= data_in;
                    if (row_i = 15) and (col_i = 15) then
                        state <= OUTPUT;
                        out_idx <= 0;
                    end if;
                end if;
            elsif state = OUTPUT then
                r_i := out_idx / 8;
                c_i := out_idx mod 8;

                p00 := to_integer(unsigned(image(2*r_i,     2*c_i)));
                p01 := to_integer(unsigned(image(2*r_i,     2*c_i + 1)));
                p10 := to_integer(unsigned(image(2*r_i + 1, 2*c_i)));
                p11 := to_integer(unsigned(image(2*r_i + 1, 2*c_i + 1)));

                hp_top := scale_181_256(p00 - p01);
                hp_bot := scale_181_256(p10 - p11);
                lh_val := scale_181_256(hp_top + hp_bot);

                data_out <= std_logic_vector(to_signed(lh_val, 16));
                out_row <= std_logic_vector(to_unsigned(r_i, 3));
                out_col <= std_logic_vector(to_unsigned(c_i, 3));
                valid_out <= '1';

                if out_idx = 63 then
                    out_idx <= 0;
                    state <= IDLE;
                else
                    out_idx <= out_idx + 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
