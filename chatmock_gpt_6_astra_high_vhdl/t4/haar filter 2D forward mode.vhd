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
    type image_memory_t is array (0 to 255) of
        std_logic_vector(7 downto 0);
    signal image_memory : image_memory_t;

    type state_t is (LOAD_IMAGE, EMIT_LH);
    signal state : state_t;
    signal coefficient_index : integer range 0 to 63;

    constant HAAR_SCALE : integer := 181;
    constant SCALE_DIVISOR : integer := 256;
begin
    process (clk, rst_n)
        variable write_address : integer range 0 to 255;
        variable coefficient_row : integer range 0 to 7;
        variable coefficient_col : integer range 0 to 7;
        variable base_address : integer range 0 to 238;

        variable top_even    : integer range 0 to 255;
        variable top_odd     : integer range 0 to 255;
        variable bottom_even : integer range 0 to 255;
        variable bottom_odd  : integer range 0 to 255;

        variable top_high    : integer range -181 to 181;
        variable bottom_high : integer range -181 to 181;
        variable lh_value    : integer range -512 to 511;
    begin
        if rst_n = '0' then
            state             <= LOAD_IMAGE;
            coefficient_index <= 0;
            data_out          <= (others => '0');
            valid_out         <= '0';
            out_row           <= (others => '0');
            out_col           <= (others => '0');

        elsif rising_edge(clk) then
            valid_out <= '0';

            case state is
                when LOAD_IMAGE =>
                    if valid_in = '1' then
                        write_address :=
                            to_integer(unsigned(row)) * 16 +
                            to_integer(unsigned(col));

                        image_memory(write_address) <= data_in;

                        if row = "1111" and col = "1111" then
                            coefficient_index <= 0;
                            state <= EMIT_LH;
                        end if;
                    end if;

                when EMIT_LH =>
                    coefficient_row := coefficient_index / 8;
                    coefficient_col := coefficient_index mod 8;
                    base_address :=
                        coefficient_row * 32 + coefficient_col * 2;

                    top_even :=
                        to_integer(unsigned(image_memory(base_address)));
                    top_odd :=
                        to_integer(unsigned(image_memory(base_address + 1)));
                    bottom_even :=
                        to_integer(unsigned(image_memory(base_address + 16)));
                    bottom_odd :=
                        to_integer(unsigned(image_memory(base_address + 17)));

                    -- Quantize after each Haar stage.
                    -- Integer division truncates toward zero.
                    top_high :=
                        ((top_even - top_odd) * HAAR_SCALE) /
                        SCALE_DIVISOR;
                    bottom_high :=
                        ((bottom_even - bottom_odd) * HAAR_SCALE) /
                        SCALE_DIVISOR;

                    lh_value :=
                        ((top_high + bottom_high) * HAAR_SCALE) /
                        SCALE_DIVISOR;

                    data_out <= std_logic_vector(to_signed(lh_value, 16));
                    out_row <= std_logic_vector(
                        to_unsigned(coefficient_row, 3));
                    out_col <= std_logic_vector(
                        to_unsigned(coefficient_col, 3));
                    valid_out <= '1';

                    if coefficient_index = 63 then
                        coefficient_index <= 0;
                        state <= LOAD_IMAGE;
                    else
                        coefficient_index <= coefficient_index + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
