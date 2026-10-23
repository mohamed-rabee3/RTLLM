library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_wavelet_lh_only is
    port (
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
end entity haar_wavelet_lh_only;

architecture rtl of haar_wavelet_lh_only is
    type image_type is array (0 to 255) of unsigned(7 downto 0);
    signal image : image_type;

    type state_type is (LOAD_IMAGE, EMIT_LH);
    signal state : state_type;

    signal coeff_row : integer range 0 to 7;
    signal coeff_col : integer range 0 to 7;

    signal write_enable  : std_logic;
    signal write_address : integer range 0 to 255;
begin
    write_enable <= '1' when rst_n = '1' and
                             state = LOAD_IMAGE and
                             valid_in = '1'
                    else '0';

    write_address <= to_integer(unsigned(row)) * 16 +
                     to_integer(unsigned(col));

    -- The image buffer need not be reset: a complete image is loaded
    -- before coefficient generation begins.
    image_write : process (clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                image(write_address) <= unsigned(data_in);
            end if;
        end if;
    end process;

    transform : process (clk, rst_n)
        variable top_address    : integer range 0 to 238;
        variable bottom_address : integer range 16 to 254;
        variable top_difference : integer range -255 to 255;
        variable bot_difference : integer range -255 to 255;
        variable top_high       : integer range -181 to 181;
        variable bottom_high    : integer range -181 to 181;
        variable lh_value       : integer range -256 to 256;
    begin
        if rst_n = '0' then
            state      <= LOAD_IMAGE;
            coeff_row  <= 0;
            coeff_col  <= 0;
            data_out   <= (others => '0');
            valid_out  <= '0';
            out_row    <= (others => '0');
            out_col    <= (others => '0');

        elsif rising_edge(clk) then
            valid_out <= '0';

            case state is
                when LOAD_IMAGE =>
                    if valid_in = '1' then
                        if row = "1111" and col = "1111" then
                            coeff_row <= 0;
                            coeff_col <= 0;
                            state     <= EMIT_LH;
                        end if;
                    end if;

                when EMIT_LH =>
                    top_address    := coeff_row * 32 + coeff_col * 2;
                    bottom_address := top_address + 16;

                    top_difference :=
                        to_integer(image(top_address)) -
                        to_integer(image(top_address + 1));

                    bot_difference :=
                        to_integer(image(bottom_address)) -
                        to_integer(image(bottom_address + 1));

                    -- Apply each fixed-point scale separately.
                    -- Integer division truncates toward zero.
                    top_high    := (top_difference * 181) / 256;
                    bottom_high := (bot_difference * 181) / 256;
                    lh_value    := ((top_high + bottom_high) * 181) / 256;

                    data_out  <= std_logic_vector(to_signed(lh_value, 16));
                    out_row   <= std_logic_vector(to_unsigned(coeff_row, 3));
                    out_col   <= std_logic_vector(to_unsigned(coeff_col, 3));
                    valid_out <= '1';

                    if coeff_col = 7 then
                        coeff_col <= 0;
                        if coeff_row = 7 then
                            coeff_row <= 0;
                            state     <= LOAD_IMAGE;
                        else
                            coeff_row <= coeff_row + 1;
                        end if;
                    else
                        coeff_col <= coeff_col + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
