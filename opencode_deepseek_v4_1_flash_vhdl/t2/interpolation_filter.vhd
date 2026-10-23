library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_interpolator is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(15 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end fir_interpolator;

architecture rtl of fir_interpolator is
    constant L : integer := 8;

    type state_t is (IDLE, INTERP);

    signal state         : state_t := IDLE;
    signal have_prev     : std_logic := '0';
    signal prev          : signed(15 downto 0) := (others => '0');
    signal cur           : signed(15 downto 0) := (others => '0');
    signal phase         : integer range 1 to L := 1;
    signal valid_out_reg : std_logic := '0';
    signal data_out_reg  : signed(15 downto 0) := (others => '0');
    signal pending_valid : std_logic := '0';
    signal pending_data  : signed(15 downto 0) := (others => '0');

    function interp_sample(prev, cur : signed(15 downto 0); k : integer)
        return signed(15 downto 0) is
        variable d     : signed(16 downto 0);
        variable d20   : signed(19 downto 0);
        variable prod  : signed(19 downto 0);
        variable delta : signed(16 downto 0);
        variable sum   : signed(17 downto 0);
    begin
        d := resize(cur, 17) - resize(prev, 17);
        d20 := resize(d, 20);

        case k is
            when 1 => prod := d20;
            when 2 => prod := shift_left(d20, 1);
            when 3 => prod := d20 + shift_left(d20, 1);
            when 4 => prod := shift_left(d20, 2);
            when 5 => prod := d20 + shift_left(d20, 2);
            when 6 => prod := shift_left(d20, 1) + shift_left(d20, 2);
            when 7 => prod := d20 + shift_left(d20, 1) + shift_left(d20, 2);
            when 8 => prod := shift_left(d20, 3);
            when others => prod := (others => '0');
        end case;

        if prod >= 0 then
            delta := resize(shift_right(prod, 3), 17);
        else
            delta := -resize(shift_right(-prod, 3), 17);
        end if;

        sum := resize(prev, 18) + resize(delta, 18);
        return resize(sum, 16);
    end function;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                have_prev <= '0';
                prev <= (others => '0');
                cur <= (others => '0');
                phase <= 1;
                valid_out_reg <= '0';
                data_out_reg <= (others => '0');
                pending_valid <= '0';
                pending_data <= (others => '0');
            else
                valid_out_reg <= '0';

                if state = INTERP then
                    data_out_reg <= interp_sample(prev, cur, phase);
                    valid_out_reg <= '1';
                    if phase = L then
                        state <= IDLE;
                        prev <= cur;
                        phase <= 1;
                    else
                        phase <= phase + 1;
                    end if;
                end if;

                if have_prev = '0' then
                    if valid_in = '1' then
                        data_out_reg <= signed(data_in);
                        valid_out_reg <= '1';
                        prev <= signed(data_in);
                        have_prev <= '1';
                        state <= IDLE;
                        pending_valid <= '0';
                    end if;
                else
                    if state = IDLE then
                        if pending_valid = '1' then
                            cur <= pending_data;
                            data_out_reg <= interp_sample(prev, pending_data, 1);
                            valid_out_reg <= '1';
                            phase <= 2;
                            state <= INTERP;
                            pending_valid <= '0';
                            if valid_in = '1' then
                                pending_data <= signed(data_in);
                                pending_valid <= '1';
                            end if;
                        elsif valid_in = '1' then
                            cur <= signed(data_in);
                            data_out_reg <= interp_sample(prev, signed(data_in), 1);
                            valid_out_reg <= '1';
                            phase <= 2;
                            state <= INTERP;
                        end if;
                    else
                        if valid_in = '1' then
                            pending_data <= signed(data_in);
                            pending_valid <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    valid_out <= valid_out_reg;
    data_out <= std_logic_vector(data_out_reg);

end rtl;
