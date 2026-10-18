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

    type state_t is (IDLE, WRITE, OUTPUT);
    signal state : state_t;

    type ram_t is array (0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
    signal mem : ram_t;

    signal r_idx : integer range 0 to 7;
    signal c_idx : integer range 0 to 7;

    function scale_181_256(x : integer) return integer is
        variable prod : signed(31 downto 0);
    begin
        prod := to_signed(x, 16) * to_signed(181, 16);
        return to_integer(shift_right(prod, 8));
    end function;

begin

    process(clk, rst_n)
        variable p00, p01, p10, p11 : integer range 0 to 255;
        variable top_hp, bot_hp    : integer range -512 to 511;
        variable coeff             : integer range -32768 to 32767;
    begin
        if rst_n = '0' then
            state     <= IDLE;
            r_idx     <= 0;
            c_idx     <= 0;
            data_out  <= (others => '0');
            valid_out <= '0';
            out_row   <= (others => '0');
            out_col   <= (others => '0');

        elsif rising_edge(clk) then
            valid_out <= '0';

            case state is

                when IDLE =>
                    if valid_in = '1' then
                        mem(to_integer(unsigned(row)), to_integer(unsigned(col))) <= data_in;
                        if (row = "1111") and (col = "1111") then
                            state <= OUTPUT;
                            r_idx <= 0;
                            c_idx <= 0;
                        else
                            state <= WRITE;
                        end if;
                    end if;

                when WRITE =>
                    if valid_in = '1' then
                        mem(to_integer(unsigned(row)), to_integer(unsigned(col))) <= data_in;
                        if (row = "1111") and (col = "1111") then
                            state <= OUTPUT;
                            r_idx <= 0;
                            c_idx <= 0;
                        end if;
                    end if;

                when OUTPUT =>
                    p00 := to_integer(unsigned(mem(2*r_idx,     2*c_idx    )));
                    p01 := to_integer(unsigned(mem(2*r_idx,     2*c_idx + 1)));
                    p10 := to_integer(unsigned(mem(2*r_idx + 1, 2*c_idx    )));
                    p11 := to_integer(unsigned(mem(2*r_idx + 1, 2*c_idx + 1)));

                    top_hp := scale_181_256(p00 - p01);
                    bot_hp := scale_181_256(p10 - p11);
                    coeff  := scale_181_256(top_hp + bot_hp);

                    data_out  <= std_logic_vector(to_signed(coeff, 16));
                    valid_out <= '1';
                    out_row   <= std_logic_vector(to_unsigned(r_idx, 3));
                    out_col   <= std_logic_vector(to_unsigned(c_idx, 3));

                    if c_idx = 7 then
                        c_idx <= 0;
                        if r_idx = 7 then
                            state <= IDLE;
                            r_idx <= 0;
                        else
                            r_idx <= r_idx + 1;
                        end if;
                    else
                        c_idx <= c_idx + 1;
                    end if;

            end case;
        end if;
    end process;

end rtl;
