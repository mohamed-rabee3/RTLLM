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
    -- Buffer input bursts while interpolation is in progress.
    -- Sustained input traffic must average no more than one sample
    -- per eight clocks, since there is no input backpressure port.
    constant FIFO_DEPTH : positive := 1024;

    type fifo_type is array (0 to FIFO_DEPTH - 1) of
        std_logic_vector(15 downto 0);
    signal fifo : fifo_type;

    signal read_pointer  : integer range 0 to FIFO_DEPTH - 1 := 0;
    signal write_pointer : integer range 0 to FIFO_DEPTH - 1 := 0;
    signal fifo_count    : integer range 0 to FIFO_DEPTH := 0;

    signal have_previous : std_logic := '0';
    signal busy          : std_logic := '0';
    signal previous      : integer range -32768 to 32767 := 0;
    signal current       : integer range -32768 to 32767 := 0;
    signal difference    : integer range -65535 to 65535 := 0;
    signal phase         : integer range 2 to 8 := 2;

    function advance_pointer(pointer_value : integer) return integer is
    begin
        if pointer_value = FIFO_DEPTH - 1 then
            return 0;
        else
            return pointer_value + 1;
        end if;
    end function;

begin
    process (clk)
        variable next_count    : integer range 0 to FIFO_DEPTH;
        variable next_read     : integer range 0 to FIFO_DEPTH - 1;
        variable next_write    : integer range 0 to FIFO_DEPTH - 1;
        variable sample_value  : integer range -32768 to 32767;
        variable delta_value   : integer range -65535 to 65535;
        variable product_value : integer range -524280 to 524280;
        variable result_value  : integer range -32768 to 32767;
        variable sample_ready  : boolean;
        variable input_used    : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                read_pointer  <= 0;
                write_pointer <= 0;
                fifo_count    <= 0;
                have_previous <= '0';
                busy          <= '0';
                previous      <= 0;
                current       <= 0;
                difference    <= 0;
                phase         <= 2;
                valid_out     <= '0';
                data_out      <= (others => '0');
            else
                valid_out <= '0';

                next_count   := fifo_count;
                next_read    := read_pointer;
                next_write   := write_pointer;
                sample_value := 0;
                sample_ready := false;
                input_used   := false;

                if busy = '1' then
                    product_value := difference * phase;

                    -- Integer division truncates toward zero, including
                    -- when the difference is negative.
                    result_value := previous + product_value / 8;

                    data_out  <= std_logic_vector(to_signed(result_value, 16));
                    valid_out <= '1';

                    if phase = 8 then
                        previous <= current;
                        busy     <= '0';
                        phase    <= 2;
                    else
                        phase <= phase + 1;
                    end if;
                else
                    if fifo_count > 0 then
                        sample_value := to_integer(signed(fifo(read_pointer)));
                        sample_ready := true;
                        next_read    := advance_pointer(read_pointer);
                        next_count   := next_count - 1;
                    elsif valid_in = '1' then
                        -- Bypass an empty FIFO.
                        sample_value := to_integer(signed(data_in));
                        sample_ready := true;
                        input_used   := true;
                    end if;

                    if sample_ready then
                        valid_out <= '1';

                        if have_previous = '0' then
                            data_out <= std_logic_vector(
                                to_signed(sample_value, 16)
                            );
                            previous      <= sample_value;
                            have_previous <= '1';
                        else
                            delta_value  := sample_value - previous;
                            result_value := previous + delta_value / 8;

                            -- Emit phase 1 now, then phases 2 through 8
                            -- on the following seven clock cycles.
                            data_out <= std_logic_vector(
                                to_signed(result_value, 16)
                            );
                            current    <= sample_value;
                            difference <= delta_value;
                            phase      <= 2;
                            busy       <= '1';
                        end if;
                    end if;
                end if;

                if valid_in = '1' and not input_used then
                    if next_count < FIFO_DEPTH then
                        fifo(next_write) <= data_in;
                        next_write := advance_pointer(next_write);
                        next_count := next_count + 1;
                    end if;
                end if;

                read_pointer  <= next_read;
                write_pointer <= next_write;
                fifo_count    <= next_count;
            end if;
        end if;
    end process;
end architecture rtl;
