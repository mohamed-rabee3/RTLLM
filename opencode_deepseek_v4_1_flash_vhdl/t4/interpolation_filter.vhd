library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  signed(15 downto 0);
        valid_out : out std_logic;
        data_out  : out signed(15 downto 0)
    );
end fir_interpolator;

architecture rtl of fir_interpolator is
    constant L : integer := 8;
    signal prev_sample : signed(15 downto 0) := (others => '0');
    signal cur_sample  : signed(15 downto 0) := (others => '0');
    signal first_sample: std_logic := '1';
    signal active      : std_logic := '0';
    signal phase       : integer range 0 to L := 0;
    signal valid_out_reg : std_logic := '0';
    signal data_out_reg  : signed(15 downto 0) := (others => '0');

    function interp(
        prev : signed(15 downto 0);
        cur  : signed(15 downto 0);
        k    : integer range 1 to L
    ) return signed(15 downto 0) is
        variable diff : signed(16 downto 0);
        variable prod : signed(21 downto 0);
        variable quot : signed(17 downto 0);
        variable sum  : signed(17 downto 0);
        variable k_s  : signed(4 downto 0);
    begin
        k_s := to_signed(k, 5);
        diff := resize(cur, 17) - resize(prev, 17);
        prod := diff * k_s;
        quot := resize(prod / to_signed(8, 5), 18);
        sum := resize(prev, 18) + quot;
        return resize(sum, 16);
    end function;

begin
    data_out <= data_out_reg;
    valid_out <= valid_out_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                prev_sample <= (others => '0');
                cur_sample <= (others => '0');
                first_sample <= '1';
                active <= '0';
                phase <= 0;
                valid_out_reg <= '0';
                data_out_reg <= (others => '0');
            else
                valid_out_reg <= '0';

                if active = '1' then
                    if phase = L then
                        if valid_in = '1' then
                            prev_sample <= cur_sample;
                            cur_sample <= data_in;
                            phase <= 1;
                            data_out_reg <= interp(cur_sample, data_in, 1);
                            valid_out_reg <= '1';
                            active <= '1';
                        else
                            active <= '0';
                            phase <= 0;
                            prev_sample <= cur_sample;
                        end if;
                    else
                        phase <= phase + 1;
                        data_out_reg <= interp(prev_sample, cur_sample, phase + 1);
                        valid_out_reg <= '1';
                    end if;
                else
                    if valid_in = '1' then
                        if first_sample = '1' then
                            prev_sample <= data_in;
                            first_sample <= '0';
                            data_out_reg <= data_in;
                            valid_out_reg <= '1';
                            phase <= 0;
                            active <= '0';
                        else
                            cur_sample <= data_in;
                            phase <= 1;
                            data_out_reg <= interp(prev_sample, data_in, 1);
                            valid_out_reg <= '1';
                            active <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
