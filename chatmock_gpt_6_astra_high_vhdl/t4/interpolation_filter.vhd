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

    -- Buffer input bursts while an interpolation segment is emitted.
    -- Sustained input traffic must not exceed the factor-8 output capacity.
    type sample_fifo_t is array (0 to FIFO_DEPTH - 1) of
        std_logic_vector(15 downto 0);

    signal sample_fifo : sample_fifo_t;
    signal read_ptr    : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal write_ptr   : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal fifo_count  : natural range 0 to FIFO_DEPTH := 0;

    signal have_previous : std_logic := '0';
    signal previous      : integer range -32768 to 32767 := 0;
    signal difference    : integer range -65535 to 65535 := 0;

    -- Phase zero is idle. Phase one is emitted when a sample is consumed.
    signal phase : natural range 0 to L := 0;

    function next_pointer(p : natural) return natural is
    begin
        if p = FIFO_DEPTH - 1 then
            return 0;
        else
            return p + 1;
        end if;
    end function;
begin
    process (clk)
        variable count_v        : natural range 0 to FIFO_DEPTH;
        variable sample_v       : integer range -32768 to 32767;
        variable difference_v   : integer range -65535 to 65535;
        variable result_v       : integer;
        variable sample_ready_v : boolean;
        variable bypass_v       : boolean;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                read_ptr     <= 0;
                write_ptr    <= 0;
                fifo_count   <= 0;
                have_previous <= '0';
                previous     <= 0;
                difference   <= 0;
                phase        <= 0;
                valid_out    <= '0';
                data_out     <= (others => '0');
            else
                valid_out <= '0';

                count_v        := fifo_count;
                sample_v       := 0;
                sample_ready_v := false;
                bypass_v       := false;

                if phase = 0 then
                    if fifo_count /= 0 then
                        sample_v := to_integer(signed(sample_fifo(read_ptr)));
                        sample_ready_v := true;
                        read_ptr <= next_pointer(read_ptr);
                        count_v := count_v - 1;
                    elsif valid_in = '1' then
                        -- An empty queue permits immediate sample consumption.
                        sample_v := to_integer(signed(data_in));
                        sample_ready_v := true;
                        bypass_v := true;
                    end if;

                    if sample_ready_v then
                        valid_out <= '1';

                        if have_previous = '0' then
                            data_out <= std_logic_vector(to_signed(sample_v, 16));
                            previous <= sample_v;
                            have_previous <= '1';
                        else
                            difference_v := sample_v - previous;
                            difference <= difference_v;

                            -- Integer division truncates toward zero, including
                            -- when the interpolation difference is negative.
                            result_v := previous + difference_v / L;
                            data_out <= std_logic_vector(to_signed(result_v, 16));
                            phase <= 2;
                        end if;
                    end if;
                else
                    result_v := previous + (difference * phase) / L;
                    data_out <= std_logic_vector(to_signed(result_v, 16));
                    valid_out <= '1';

                    if phase = L then
                        previous <= result_v;
                        phase <= 0;
                    else
                        phase <= phase + 1;
                    end if;
                end if;

                -- A dequeue and enqueue may occur on the same clock.
                if valid_in = '1' and not bypass_v then
                    if count_v < FIFO_DEPTH then
                        sample_fifo(write_ptr) <= data_in;
                        write_ptr <= next_pointer(write_ptr);
                        count_v := count_v + 1;
                    end if;
                end if;

                fifo_count <= count_v;
            end if;
        end if;
    end process;
end architecture rtl;
