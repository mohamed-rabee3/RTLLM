library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fifo_math_pkg is
    function clog2(value : positive) return natural;
    function is_power_of_two(value : positive) return boolean;
end package fifo_math_pkg;

package body fifo_math_pkg is
    function clog2(value : positive) return natural is
        variable remainder : natural := value - 1;
        variable result    : natural := 0;
    begin
        while remainder > 0 loop
            remainder := remainder / 2;
            result := result + 1;
        end loop;
        return result;
    end function;

    function is_power_of_two(value : positive) return boolean is
        variable remainder : positive := value;
    begin
        while remainder > 1 loop
            if (remainder mod 2) /= 0 then
                return false;
            end if;
            remainder := remainder / 2;
        end loop;
        return true;
    end function;
end package body fifo_math_pkg;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_math_pkg.all;

entity dual_port_RAM is
    generic (
        DEPTH : positive := 16;
        WIDTH : positive := 8
    );
    port (
        wclk  : in  std_logic;
        wenc  : in  std_logic;
        waddr : in  std_logic_vector(clog2(DEPTH)-1 downto 0);
        wdata : in  std_logic_vector(WIDTH-1 downto 0);
        rclk  : in  std_logic;
        renc  : in  std_logic;
        raddr : in  std_logic_vector(clog2(DEPTH)-1 downto 0);
        rdata : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity dual_port_RAM;

architecture rtl of dual_port_RAM is
    type ram_type is array (0 to DEPTH-1) of
        std_logic_vector(WIDTH-1 downto 0);

    signal RAM_MEM : ram_type;
begin
    process (wclk)
    begin
        if rising_edge(wclk) then
            if wenc = '1' then
                RAM_MEM(to_integer(unsigned(waddr))) <= wdata;
            end if;
        end if;
    end process;

    process (rclk)
    begin
        if rising_edge(rclk) then
            if renc = '1' then
                rdata <= RAM_MEM(to_integer(unsigned(raddr)));
            end if;
        end if;
    end process;
end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_math_pkg.all;

entity asyn_fifo is
    generic (
        DEPTH : positive := 16;
        WIDTH : positive := 8
    );
    port (
        wclk   : in  std_logic;
        rclk   : in  std_logic;
        wrstn  : in  std_logic;
        rrstn  : in  std_logic;
        winc   : in  std_logic;
        rinc   : in  std_logic;
        wdata  : in  std_logic_vector(WIDTH-1 downto 0);
        wfull  : out std_logic;
        rempty : out std_logic;
        rdata  : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity asyn_fifo;

architecture rtl of asyn_fifo is
    constant ADDR_WIDTH : natural := clog2(DEPTH);
    constant PTR_WIDTH  : natural := ADDR_WIDTH + 1;

    subtype pointer_type is unsigned(PTR_WIDTH-1 downto 0);

    signal waddr_bin      : pointer_type;
    signal raddr_bin      : pointer_type;
    signal waddr_bin_next : pointer_type;
    signal raddr_bin_next : pointer_type;

    signal wptr : pointer_type;
    signal rptr : pointer_type;

    -- Read-pointer synchronizer in the write-clock domain.
    signal rptr_buff : pointer_type;
    signal rptr_syn  : pointer_type;

    -- Write-pointer synchronizer in the read-clock domain.
    signal wptr_buff : pointer_type;
    signal wptr_syn  : pointer_type;

    signal wfull_int  : std_logic;
    signal rempty_int : std_logic;
    signal wen        : std_logic;
    signal ren        : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of rptr_buff : signal is "TRUE";
    attribute ASYNC_REG of rptr_syn  : signal is "TRUE";
    attribute ASYNC_REG of wptr_buff : signal is "TRUE";
    attribute ASYNC_REG of wptr_syn  : signal is "TRUE";

    function binary_to_gray(value : pointer_type) return pointer_type is
    begin
        return value xor shift_right(value, 1);
    end function;

    function full_compare_pointer(value : pointer_type)
        return pointer_type is
        variable result : pointer_type := value;
    begin
        result(PTR_WIDTH-1) := not value(PTR_WIDTH-1);
        if PTR_WIDTH > 1 then
            result(PTR_WIDTH-2) := not value(PTR_WIDTH-2);
        end if;
        return result;
    end function;
begin
    assert DEPTH >= 2 and is_power_of_two(DEPTH)
        report "asyn_fifo: DEPTH must be a power of two and at least 2"
        severity failure;

    wfull_int <= '1'
        when wptr = full_compare_pointer(rptr_syn)
        else '0';

    rempty_int <= '1' when rptr = wptr_syn else '0';

    wfull  <= wfull_int;
    rempty <= rempty_int;

    wen <= winc and not wfull_int and wrstn;
    ren <= rinc and not rempty_int and rrstn;

    waddr_bin_next <= waddr_bin + 1 when wen = '1' else waddr_bin;
    raddr_bin_next <= raddr_bin + 1 when ren = '1' else raddr_bin;

    process (wclk, wrstn)
    begin
        if wrstn = '0' then
            waddr_bin <= (others => '0');
            wptr      <= (others => '0');
        elsif rising_edge(wclk) then
            waddr_bin <= waddr_bin_next;
            wptr      <= binary_to_gray(waddr_bin_next);
        end if;
    end process;

    process (rclk, rrstn)
    begin
        if rrstn = '0' then
            raddr_bin <= (others => '0');
            rptr      <= (others => '0');
        elsif rising_edge(rclk) then
            raddr_bin <= raddr_bin_next;
            rptr      <= binary_to_gray(raddr_bin_next);
        end if;
    end process;

    process (wclk, wrstn)
    begin
        if wrstn = '0' then
            rptr_buff <= (others => '0');
            rptr_syn  <= (others => '0');
        elsif rising_edge(wclk) then
            rptr_buff <= rptr;
            rptr_syn  <= rptr_buff;
        end if;
    end process;

    process (rclk, rrstn)
    begin
        if rrstn = '0' then
            wptr_buff <= (others => '0');
            wptr_syn  <= (others => '0');
        elsif rising_edge(rclk) then
            wptr_buff <= wptr;
            wptr_syn  <= wptr_buff;
        end if;
    end process;

    u_ram : entity work.dual_port_RAM(rtl)
        generic map (
            DEPTH => DEPTH,
            WIDTH => WIDTH
        )
        port map (
            wclk  => wclk,
            wenc  => wen,
            waddr => std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0)),
            wdata => wdata,
            rclk  => rclk,
            renc  => ren,
            raddr => std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0)),
            rdata => rdata
        );
end architecture rtl;
