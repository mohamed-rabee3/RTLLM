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

    type sample_fifo_t is array (0 to FIFO_DEPTH - 1) of
        std_logic_vector(15 downto 0);

    signal sample_fifo : sample_fifo_t;
    signal read_ptr    : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal write_ptr   : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal fifo_count  : natural range 0 to FIFO_DEPTH := 0;

    signal have_previous : std_logic := '0';
    signal busy          : std_logic := '0';
    signal previous      : integer range -32768 to 32767 := 0;
    signal segment_start : integer range -32768 to 32767 := 0;
    signal segment_delta : integer range -65535 to 65535 := 0;
    signal phase         : natural range 2 to L := 2;

    function next_pointer(pointer_value : natural) return natural is
    begin
        if pointer_value = FIFO_DEPTH - 1 then
            return 0;
        else
            return pointer_value + 1;
        end if;
    end function;
begin
    -- The FIFO absorbs input bursts. Sustained input traffic must allow
    -- eight output clocks per sample, and bursts must fit in the FIFO.
    process (clk)
        variable pop_fifo      : boolean;
        variable push_fifo     : boolean;
        variable sample_ready  : boolean;
        variable current_value : integer range -32768 to 32767;
        variable delta_value   : integer range -65535 to 65535;
        variable output_value  : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                read_ptr      <= 0;
                write_ptr     <= 0;
                fifo_count    <= 0;
                have_previous <= '0';
                busy          <= '0';
                previous      <= 0;
                segment_start <= 0;
                segment_delta <= 0;
                phase         <= 2;
                valid_out     <= '0';
                data_out      <= (others => '0');
            else
                valid_out <= '0';

                pop_fifo := (busy = '0') and (fifo_count > 0);

                -- An idle, empty FIFO is bypassed for immediate processing.
                push_fifo := (valid_in = '1') and
                             ((busy = '1') or (fifo_count > 0)) and
                             ((fifo_count < FIFO_DEPTH) or pop_fifo);

                if push_fifo then
                    sample_fifo(write_ptr) <= data_in;
                    write_ptr <= next_pointer(write_ptr);
                end if;

                if pop_fifo then
                    read_ptr <= next_pointer(read_ptr);
                end if;

                if push_fifo and not pop_fifo then
                    fifo_count <= fifo_count + 1;
                elsif pop_fifo and not push_fifo then
                    fifo_count <= fifo_count - 1;
                end if;

                if busy = '1' then
                    -- Integer division truncates toward zero, including
                    -- negative differences; no arithmetic shift is used.
                    output_value := segment_start +
                                     (segment_delta * phase) / L;
                    data_out  <= std_logic_vector(to_signed(output_value, 16));
                    valid_out <= '1';

                    if phase = L then
                        busy  <= '0';
                        phase <= 2;
                    else
                        phase <= phase + 1;
                    end if;
                else
                    sample_ready  := false;
                    current_value := 0;

                    if pop_fifo then
                        current_value :=
                            to_integer(signed(sample_fifo(read_ptr)));
                        sample_ready := true;
                    elsif valid_in = '1' then
                        current_value := to_integer(signed(data_in));
                        sample_ready := true;
                    end if;

                    if sample_ready then
                        valid_out <= '1';

                        if have_previous = '0' then
                            -- Emit the very first sample without interpolation.
                            data_out <=
                                std_logic_vector(to_signed(current_value, 16));
                            previous      <= current_value;
                            have_previous <= '1';
                        else
                            -- Emit phase 1 now, followed by phases 2 through 8.
                            delta_value  := current_value - previous;
                            output_value := previous + delta_value / L;

                            data_out <=
                                std_logic_vector(to_signed(output_value, 16));

                            segment_start <= previous;
                            segment_delta <= delta_value;
                            previous      <= current_value;
                            phase         <= 2;
                            busy          <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
