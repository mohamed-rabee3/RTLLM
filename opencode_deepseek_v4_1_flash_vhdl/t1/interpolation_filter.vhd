library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    port (
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

    type state_t is (IDLE, INTERP);

    signal state         : state_t;
    signal first         : std_logic;
    signal prev          : signed(15 downto 0);
    signal base          : signed(15 downto 0);
    signal delta         : signed(16 downto 0);
    signal phase         : integer range 1 to L;
    signal pending_valid : std_logic;
    signal pending_data  : signed(15 downto 0);

    function interp_value (
        base_val  : signed(15 downto 0);
        delta_val : signed(16 downto 0);
        phase_val : integer
    ) return signed is
        variable prod : signed(21 downto 0);
        variable quot : signed(21 downto 0);
        variable res  : signed(16 downto 0);
    begin
        prod := delta_val * to_signed(phase_val, 5);

        if prod >= 0 then
            quot := shift_right(prod, 3);
        else
            quot := shift_right(prod + to_signed(7, prod'length), 3);
        end if;

        res := resize(base_val, 17) + resize(quot, 17);
        return resize(res, 16);
    end function;

begin
    process(clk)
        variable v_delta : signed(16 downto 0);
        variable v_out   : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state         <= IDLE;
                first         <= '0';
                valid_out     <= '0';
                data_out      <= (others => '0');
                prev          <= (others => '0');
                base          <= (others => '0');
                delta         <= (others => '0');
                phase         <= 1;
                pending_valid <= '0';
                pending_data  <= (others => '0');
            else
                valid_out <= '0';

                case state is
                    when IDLE =>
                        if valid_in = '1' then
                            if first = '0' then
                                data_out <= data_in;
                                valid_out <= '1';
                                prev <= data_in;
                                first <= '1';
                            else
                                v_delta := resize(data_in, 17) - resize(prev, 17);
                                v_out := interp_value(prev, v_delta, 1);
                                data_out <= v_out;
                                valid_out <= '1';
                                base <= prev;
                                delta <= v_delta;
                                prev <= data_in;
                                phase <= 2;
                                state <= INTERP;
                            end if;
                        end if;

                    when INTERP =>
                        v_out := interp_value(base, delta, phase);
                        data_out <= v_out;
                        valid_out <= '1';

                        if phase = L then
                            if valid_in = '1' then
                                v_delta := resize(data_in, 17) - resize(prev, 17);
                                base <= prev;
                                delta <= v_delta;
                                prev <= data_in;
                                phase <= 1;
                                state <= INTERP;
                            elsif pending_valid = '1' then
                                v_delta := resize(pending_data, 17) - resize(prev, 17);
                                base <= prev;
                                delta <= v_delta;
                                prev <= pending_data;
                                phase <= 1;
                                state <= INTERP;
                                pending_valid <= '0';
                            else
                                state <= IDLE;
                            end if;
                        else
                            phase <= phase + 1;
                            if valid_in = '1' then
                                pending_data <= data_in;
                                pending_valid <= '1';
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
end rtl;
