library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_interpolator is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        data_in   : in  std_logic_vector(15 downto 0);
        valid_out : out std_logic;
        data_out  : out std_logic_vector(15 downto 0)
    );
end entity fir_interpolator;

architecture rtl of fir_interpolator is
    constant L          : positive := 8;
    constant FIFO_DEPTH : positive := 1024;

    -- Buffer input bursts while interpolation outputs are being emitted.
    -- Sustained input traffic must not exceed the factor-8 output capacity.
    type fifo_type is array (0 to FIFO_DEPTH - 1) of signed(15 downto 0);
    signal input_fifo : fifo_type;

    signal read_ptr   : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal write_ptr  : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal fifo_count : natural range 0 to FIFO_DEPTH := 0;

    signal have_previous : std_logic := '0';
    signal previous      : integer range -32768 to 32767 := 0;
    signal current       : integer range -32768 to 32767 := 0;
    signal difference    : integer range -65535 to 65535 := 0;

    -- Zero denotes idle; phases 2 through 8 follow the initial phase-1 output.
    signal phase : natural range 0 to L := 0;

    function increment_pointer(pointer : natural) return natural is
    begin
        if pointer = FIFO_DEPTH - 1 then
            return 0;
        else
            return pointer + 1;
        end if;
    end function;
begin
    process (clk)
        variable count_next     : natural range 0 to FIFO_DEPTH;
        variable sample_value   : integer range -32768 to 32767;
        variable delta_value    : integer range -65535 to 65535;
        variable result_value   : integer;
        variable sample_ready   : boolean;
        variable input_bypassed : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                read_ptr      <= 0;
                write_ptr     <= 0;
                fifo_count    <= 0;
                have_previous <= '0';
                previous      <= 0;
                current       <= 0;
                difference    <= 0;
                phase         <= 0;
                valid_out     <= '0';
                data_out      <= (others => '0');
            else
                valid_out     <= '0';
                count_next     := fifo_count;
                sample_value   := 0;
                sample_ready   := false;
                input_bypassed := false;

                if phase /= 0 then
                    -- Integer division truncates toward zero, including
                    -- for negative differences.
                    result_value := previous + (difference * phase) / L;
                    data_out     <= std_logic_vector(to_signed(result_value, 16));
                    valid_out    <= '1';

                    if phase = L then
                        previous <= current;
                        phase    <= 0;
                    else
                        phase <= phase + 1;
                    end if;
                else
                    if fifo_count /= 0 then
                        sample_value := to_integer(input_fifo(read_ptr));
                        sample_ready := true;
                        read_ptr     <= increment_pointer(read_ptr);
                        count_next   := count_next - 1;
                    elsif valid_in = '1' then
                        -- Empty-FIFO bypass emits the first sample without
                        -- an additional buffering cycle.
                        sample_value   := to_integer(signed(data_in));
                        sample_ready   := true;
                        input_bypassed := true;
                    end if;

                    if sample_ready then
                        valid_out <= '1';

                        if have_previous = '0' then
                            data_out      <= std_logic_vector(to_signed(sample_value, 16));
                            previous      <= sample_value;
                            have_previous <= '1';
                        else
                            delta_value  := sample_value - previous;
                            result_value := previous + delta_value / L;

                            current    <= sample_value;
                            difference <= delta_value;
                            data_out   <= std_logic_vector(to_signed(result_value, 16));
                            phase      <= 2;
                        end if;
                    end if;
                end if;

                -- A simultaneous FIFO read makes room for an input write.
                if valid_in = '1' and not input_bypassed then
                    if count_next < FIFO_DEPTH then
                        input_fifo(write_ptr) <= signed(data_in);
                        write_ptr             <= increment_pointer(write_ptr);
                        count_next            := count_next + 1;
                    end if;
                end if;

                fifo_count <= count_next;
            end if;
        end if;
    end process;
end architecture rtl;
