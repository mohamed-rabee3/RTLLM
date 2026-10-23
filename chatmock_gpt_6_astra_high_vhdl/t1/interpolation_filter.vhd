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

    -- Buffer bursts of input samples while interpolation is active.
    -- Sustained input throughput must not exceed one sample per eight
    -- clocks, and outstanding samples must fit within this FIFO.
    type sample_fifo_t is array (0 to FIFO_DEPTH - 1) of
        std_logic_vector(15 downto 0);

    signal sample_fifo : sample_fifo_t;
    signal read_ptr    : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal write_ptr   : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal fifo_count  : natural range 0 to FIFO_DEPTH := 0;

    signal have_previous : std_logic := '0';
    signal previous      : integer range -32768 to 32767 := 0;
    signal current       : integer range -32768 to 32767 := 0;
    signal difference    : integer range -65535 to 65535 := 0;

    -- Zero denotes idle; phases 2 through 8 complete an active segment.
    -- Phase 1 is emitted when the segment's new sample is accepted.
    signal phase : natural range 0 to L := 0;
begin
    process (clk)
        variable next_read_ptr  : natural range 0 to FIFO_DEPTH - 1;
        variable next_write_ptr : natural range 0 to FIFO_DEPTH - 1;
        variable next_count     : natural range 0 to FIFO_DEPTH;

        variable input_consumed : boolean;
        variable sample_ready   : boolean;
        variable new_sample     : integer range -32768 to 32767;
        variable new_difference : integer range -65535 to 65535;
        variable result_value   : integer;
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
                valid_out <= '0';

                next_read_ptr  := read_ptr;
                next_write_ptr := write_ptr;
                next_count     := fifo_count;
                input_consumed := false;
                sample_ready   := false;
                new_sample     := 0;

                if phase /= 0 then
                    -- Integer division truncates toward zero, including
                    -- for negative differences.
                    result_value := previous + (difference * phase) / L;

                    data_out  <= std_logic_vector(to_signed(result_value, 16));
                    valid_out <= '1';

                    if phase = L then
                        previous <= current;
                        phase    <= 0;
                    else
                        phase <= phase + 1;
                    end if;
                else
                    if fifo_count /= 0 then
                        new_sample := to_integer(signed(sample_fifo(read_ptr)));
                        sample_ready := true;
                        next_count := next_count - 1;

                        if read_ptr = FIFO_DEPTH - 1 then
                            next_read_ptr := 0;
                        else
                            next_read_ptr := read_ptr + 1;
                        end if;
                    elsif valid_in = '1' then
                        -- Bypass an empty FIFO for immediate processing.
                        new_sample := to_integer(signed(data_in));
                        sample_ready := true;
                        input_consumed := true;
                    end if;

                    if sample_ready then
                        if have_previous = '0' then
                            previous      <= new_sample;
                            have_previous <= '1';
                            data_out      <= std_logic_vector(
                                                 to_signed(new_sample, 16));
                            valid_out     <= '1';
                        else
                            new_difference := new_sample - previous;
                            result_value := previous + new_difference / L;

                            current    <= new_sample;
                            difference <= new_difference;
                            phase      <= 2;
                            data_out   <= std_logic_vector(
                                              to_signed(result_value, 16));
                            valid_out  <= '1';
                        end if;
                    end if;
                end if;

                if valid_in = '1' and not input_consumed then
                    if next_count < FIFO_DEPTH then
                        sample_fifo(write_ptr) <= data_in;
                        next_count := next_count + 1;

                        if write_ptr = FIFO_DEPTH - 1 then
                            next_write_ptr := 0;
                        else
                            next_write_ptr := write_ptr + 1;
                        end if;
                    end if;
                end if;

                read_ptr   <= next_read_ptr;
                write_ptr  <= next_write_ptr;
                fifo_count <= next_count;
            end if;
        end if;
    end process;
end architecture rtl;
