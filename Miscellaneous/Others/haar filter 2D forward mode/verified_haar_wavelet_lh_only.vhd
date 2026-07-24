library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity verified_haar_wavelet_lh_only is
    port(clk       : in  std_logic;
         rst_n     : in  std_logic;
         valid_in  : in  std_logic;
         row       : in  std_logic_vector(3 downto 0);
         col       : in  std_logic_vector(3 downto 0);
         data_in   : in  std_logic_vector(7 downto 0);
         data_out  : out std_logic_vector(15 downto 0);
         valid_out : out std_logic;
         out_row   : out std_logic_vector(2 downto 0);
         out_col   : out std_logic_vector(2 downto 0));
end verified_haar_wavelet_lh_only;

architecture rtl of verified_haar_wavelet_lh_only is
    type mem_t is array(0 to 255) of std_logic_vector(7 downto 0);
    signal mem       : mem_t;
    signal emit_busy : std_logic := '0';
    signal erow      : integer range 0 to 7 := 0;
    signal ecnt      : integer range 0 to 7 := 0;

    -- (v * 181 / 256) with signed truncation toward zero (matches the golden)
    function m181(v : signed) return signed is
    begin
        return resize(resize(v, 40) * to_signed(181, 16) / to_signed(256, 16), 32);
    end function;

    function pix(m : mem_t; idx : integer) return signed is
    begin
        return signed(resize(unsigned(m(idx)), 16));
    end function;
begin
    process(clk, rst_n)
        variable rr, cc : integer range 0 to 7;
        variable lh_top, lh_bot, lh : signed(31 downto 0);
    begin
        if rst_n = '0' then
            valid_out <= '0';
            emit_busy <= '0';
            ecnt      <= 0;
            erow      <= 0;
        elsif rising_edge(clk) then
            valid_out <= '0';

            -- load
            if valid_in = '1' then
                mem(to_integer(unsigned(row)) * 16 + to_integer(unsigned(col))) <= data_in;
                if col = "1111" and row(0) = '1' then
                    erow      <= to_integer(unsigned(row(3 downto 1)));
                    ecnt      <= 0;
                    emit_busy <= '1';
                end if;
            end if;

            -- emit (may run concurrently with load)
            if emit_busy = '1' then
                rr := erow;
                cc := ecnt;
                lh_top := m181(pix(mem, (2*rr)*16 + 2*cc) - pix(mem, (2*rr)*16 + 2*cc + 1));
                lh_bot := m181(pix(mem, (2*rr+1)*16 + 2*cc) - pix(mem, (2*rr+1)*16 + 2*cc + 1));
                lh     := m181(lh_top + lh_bot);

                data_out  <= std_logic_vector(lh(15 downto 0));
                out_row   <= std_logic_vector(to_unsigned(erow, 3));
                out_col   <= std_logic_vector(to_unsigned(ecnt, 3));
                valid_out <= '1';

                if ecnt = 7 then
                    emit_busy <= '0';
                    ecnt      <= 0;
                else
                    ecnt <= ecnt + 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
