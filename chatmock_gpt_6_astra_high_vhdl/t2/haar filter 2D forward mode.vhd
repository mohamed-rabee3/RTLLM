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
    type image_memory_t is array (0 to 255) of unsigned(7 downto 0);
    signal image_memory : image_memory_t;

    type state_t is (COLLECT_IMAGE, OUTPUT_LH);
    signal state : state_t;

    signal coefficient_row : integer range 0 to 7;
    signal coefficient_col : integer range 0 to 7;
begin
    -- Image storage is deliberately not reset. A complete image is written
    -- before its coefficients are read.
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '1' then
                if state = COLLECT_IMAGE and valid_in = '1' then
                    image_memory(
                        to_integer(unsigned(row)) * 16 +
                        to_integer(unsigned(col))
                    ) <= unsigned(data_in);
                end if;
            end if;
        end if;
    end process;

    process (clk, rst_n)
        variable base_address : integer range 0 to 238;
        variable top_even     : integer range 0 to 255;
        variable top_odd      : integer range 0 to 255;
        variable bottom_even  : integer range 0 to 255;
        variable bottom_odd   : integer range 0 to 255;
        variable top_high     : integer range -180 to 180;
        variable bottom_high  : integer range -180 to 180;
        variable lh_value     : integer range -255 to 255;
    begin
        if rst_n = '0' then
            state           <= COLLECT_IMAGE;
            coefficient_row <= 0;
            coefficient_col <= 0;
            data_out        <= (others => '0');
            valid_out       <= '0';
            out_row         <= (others => '0');
            out_col         <= (others => '0');

        elsif rising_edge(clk) then
            valid_out <= '0';

            case state is
                when COLLECT_IMAGE =>
                    if valid_in = '1' and row = "1111" and col = "1111" then
                        coefficient_row <= 0;
                        coefficient_col <= 0;
                        state           <= OUTPUT_LH;
                    end if;

                when OUTPUT_LH =>
                    base_address := coefficient_row * 32 +
                                    coefficient_col * 2;

                    top_even    := to_integer(image_memory(base_address));
                    top_odd     := to_integer(image_memory(base_address + 1));
                    bottom_even := to_integer(image_memory(base_address + 16));
                    bottom_odd  := to_integer(image_memory(base_address + 17));

                    -- Apply the fixed-point scale independently at each stage.
                    -- Integer division discards the fractional part toward zero.
                    top_high    := ((top_even - top_odd) * 181) / 256;
                    bottom_high := ((bottom_even - bottom_odd) * 181) / 256;
                    lh_value    := ((top_high + bottom_high) * 181) / 256;

                    data_out  <= std_logic_vector(to_signed(lh_value, 16));
                    valid_out <= '1';
                    out_row   <= std_logic_vector(to_unsigned(coefficient_row, 3));
                    out_col   <= std_logic_vector(to_unsigned(coefficient_col, 3));

                    if coefficient_col = 7 then
                        coefficient_col <= 0;
                        if coefficient_row = 7 then
                            coefficient_row <= 0;
                            state           <= COLLECT_IMAGE;
                        else
                            coefficient_row <= coefficient_row + 1;
                        end if;
                    else
                        coefficient_col <= coefficient_col + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
