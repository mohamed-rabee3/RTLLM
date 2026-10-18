library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        valid_in : in  std_logic;
        data_in  : in  signed(15 downto 0);
        valid_out: out std_logic;
        data_out : out signed(15 downto 0)
    );
end fir_interpolator;

architecture Behavioral of fir_interpolator is

    function div8_trunc(val : signed(21 downto 0)) return signed is
        variable mag : unsigned(21 downto 0);
        variable q   : signed(21 downto 0);
    begin
        if val >= 0 then
            q := shift_right(val, 3);
        else
            mag := unsigned(-val);
            q := -signed(shift_right(mag, 3));
        end if;
        return q;
    end function;

    signal prev_sample   : signed(15 downto 0);
    signal target_sample : signed(15 downto 0);
    signal pending_sample: signed(15 downto 0);
    signal prev_ext      : signed(16 downto 0);
    signal target_ext    : signed(16 downto 0);
    signal delta         : signed(16 downto 0);
    signal phase_s       : signed(4 downto 0);
    signal term          : signed(21 downto 0);
    signal quot          : signed(21 downto 0);
    signal interp17      : signed(16 downto 0);
    signal data_out_reg  : signed(15 downto 0);
    signal valid_out_reg : std_logic;
    signal has_prev      : std_logic;
    signal busy          : std_logic;
    signal pending_flag  : std_logic;
    signal phase         : integer range 0 to 8;

begin

    prev_ext   <= resize(prev_sample, 17);
    target_ext <= resize(target_sample, 17);
    delta      <= target_ext - prev_ext;
    phase_s    <= to_signed(phase, 5);
    term       <= delta * phase_s;
    quot       <= div8_trunc(term);
    interp17   <= prev_ext + resize(quot, 17);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out_reg <= '0';
                data_out_reg  <= (others => '0');
                prev_sample   <= (others => '0');
                target_sample <= (others => '0');
                pending_sample<= (others => '0');
                has_prev      <= '0';
                busy          <= '0';
                pending_flag  <= '0';
                phase         <= 0;
            else
                valid_out_reg <= '0';
                if busy = '1' then
                    valid_out_reg <= '1';
                    data_out_reg  <= resize(interp17, 16);
                    if phase = 8 then
                        prev_sample <= target_sample;
                        if pending_flag = '1' then
                            target_sample <= pending_sample;
                            phase <= 1;
                            busy <= '1';
                            if valid_in = '1' then
                                pending_sample <= data_in;
                                pending_flag <= '1';
                            else
                                pending_flag <= '0';
                            end if;
                        elsif valid_in = '1' then
                            target_sample <= data_in;
                            phase <= 1;
                            busy <= '1';
                        else
                            phase <= 0;
                            busy <= '0';
                        end if;
                    else
                        phase <= phase + 1;
                        if valid_in = '1' then
                            pending_sample <= data_in;
                            pending_flag <= '1';
                        end if;
                    end if;
                else
                    pending_flag <= '0';
                    if valid_in = '1' then
                        if has_prev = '0' then
                            valid_out_reg <= '1';
                            data_out_reg  <= data_in;
                            prev_sample   <= data_in;
                            has_prev      <= '1';
                            phase         <= 0;
                            busy          <= '0';
                        else
                            target_sample <= data_in;
                            phase <= 1;
                            busy <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    valid_out <= valid_out_reg;
    data_out  <= data_out_reg;

end Behavioral;
