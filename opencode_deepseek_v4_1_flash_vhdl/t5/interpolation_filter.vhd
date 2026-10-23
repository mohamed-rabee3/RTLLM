library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        data_in : in signed(15 downto 0);
        valid_out : out std_logic;
        data_out : out signed(15 downto 0)
    );
end fir_interpolator;

architecture rtl of fir_interpolator is
    function div8_trunc(x : signed) return signed is
        variable ax : signed(x'range);
        variable q : signed(x'range);
    begin
        if x >= 0 then
            q := shift_right(x, 3);
        else
            ax := -x;
            q := shift_right(ax, 3);
            q := -q;
        end if;
        return q;
    end function;

    function linear_interp(prev, cur : signed(15 downto 0); k : integer) return signed(15 downto 0) is
        variable diff : signed(16 downto 0);
        variable prod : signed(21 downto 0);
        variable quot : signed(21 downto 0);
        variable sum : signed(17 downto 0);
    begin
        diff := resize(cur, 17) - resize(prev, 17);
        prod := diff * to_signed(k, 5);
        quot := div8_trunc(prod);
        sum := resize(prev, 18) + resize(quot, 18);
        return resize(sum, 16);
    end function;

    signal valid_out_r : std_logic := '0';
    signal data_out_r : signed(15 downto 0) := (others => '0');
    signal prev_sample : signed(15 downto 0) := (others => '0');
    signal cur_sample : signed(15 downto 0) := (others => '0');
    signal prev_valid : std_logic := '0';
    signal busy : std_logic := '0';
    signal phase : integer range 0 to 8 := 0;
    signal pending_valid : std_logic := '0';
    signal pending_sample : signed(15 downto 0) := (others => '0');
begin
    valid_out <= valid_out_r;
    data_out <= data_out_r;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out_r <= '0';
                data_out_r <= (others => '0');
                prev_sample <= (others => '0');
                cur_sample <= (others => '0');
                prev_valid <= '0';
                busy <= '0';
                phase <= 0;
                pending_valid <= '0';
                pending_sample <= (others => '0');
            else
                valid_out_r <= '0';

                if busy = '1' then
                    data_out_r <= linear_interp(prev_sample, cur_sample, phase);
                    valid_out_r <= '1';
                    if phase = 8 then
                        prev_sample <= cur_sample;
                        busy <= '0';
                        phase <= 0;
                    else
                        phase <= phase + 1;
                    end if;
                end if;

                if busy = '1' and phase = 8 and pending_valid = '1' then
                    cur_sample <= pending_sample;
                    phase <= 1;
                    busy <= '1';
                    pending_valid <= '0';
                end if;

                if valid_in = '1' then
                    if prev_valid = '0' then
                        data_out_r <= data_in;
                        valid_out_r <= '1';
                        prev_sample <= data_in;
                        prev_valid <= '1';
                        busy <= '0';
                        phase <= 0;
                        pending_valid <= '0';
                    else
                        if busy = '0' then
                            data_out_r <= linear_interp(prev_sample, data_in, 1);
                            valid_out_r <= '1';
                            cur_sample <= data_in;
                            phase <= 2;
                            busy <= '1';
                            pending_valid <= '0';
                        else
                            if phase = 8 then
                                cur_sample <= data_in;
                                phase <= 1;
                                busy <= '1';
                                pending_valid <= '0';
                            else
                                pending_sample <= data_in;
                                pending_valid <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
