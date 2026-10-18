library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package asyn_fifo_pkg is
    function clog2(value : positive) return natural;
end package asyn_fifo_pkg;

package body asyn_fifo_pkg is
    function clog2(value : positive) return natural is
        variable remaining : natural := value - 1;
        variable result_v  : natural := 0;
    begin
        while remaining > 0 loop
            remaining := remaining / 2;
            result_v := result_v + 1;
        end loop;
        return result_v;
    end function;
end package body asyn_fifo_pkg;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.asyn_fifo_pkg.all;

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
use work.asyn_fifo_pkg.all;

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
    constant PTR_WIDTH  : positive := ADDR_WIDTH + 1;

    -- A complete wrap in binary inverts the two highest Gray-code bits.
    function make_full_mask return unsigned is
        variable result_v : unsigned(PTR_WIDTH-1 downto 0) :=
            (others => '0');
    begin
        result_v(PTR_WIDTH-1) := '1';
        if PTR_WIDTH >= 2 then
            result_v(PTR_WIDTH-2) := '1';
        end if;
        return result_v;
    end function;

    constant FULL_MASK : unsigned(PTR_WIDTH-1 downto 0) :=
        make_full_mask;

    signal waddr_bin      : unsigned(PTR_WIDTH-1 downto 0);
    signal raddr_bin      : unsigned(PTR_WIDTH-1 downto 0);
    signal waddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);
    signal raddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);

    signal wptr      : unsigned(PTR_WIDTH-1 downto 0);
    signal rptr      : unsigned(PTR_WIDTH-1 downto 0);
    signal wptr_buff : unsigned(PTR_WIDTH-1 downto 0);
    signal rptr_buff : unsigned(PTR_WIDTH-1 downto 0);
    signal wptr_syn  : unsigned(PTR_WIDTH-1 downto 0);
    signal rptr_syn  : unsigned(PTR_WIDTH-1 downto 0);

    signal wfull_i  : std_logic;
    signal rempty_i : std_logic;
    signal wen     : std_logic;
    signal ren     : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of wptr_buff : signal is "TRUE";
    attribute ASYNC_REG of wptr_syn  : signal is "TRUE";
    attribute ASYNC_REG of rptr_buff : signal is "TRUE";
    attribute ASYNC_REG of rptr_syn  : signal is "TRUE";
begin
    assert DEPTH >= 2 and DEPTH = 2**ADDR_WIDTH
        report "asyn_fifo: DEPTH must be a power of two and at least 2"
        severity failure;

    wfull_i  <= '1' when wptr = (rptr_syn xor FULL_MASK) else '0';
    rempty_i <= '1' when rptr = wptr_syn else '0';

    wfull  <= wfull_i;
    rempty <= rempty_i;

    wen <= winc and not wfull_i and wrstn;
    ren <= rinc and not rempty_i and rrstn;

    waddr_bin_next <= waddr_bin + 1 when wen = '1' else waddr_bin;
    raddr_bin_next <= raddr_bin + 1 when ren = '1' else raddr_bin;

    -- Write-domain binary and registered Gray pointers.
    process (wclk, wrstn)
    begin
        if wrstn = '0' then
            waddr_bin <= (others => '0');
            wptr      <= (others => '0');
        elsif rising_edge(wclk) then
            waddr_bin <= waddr_bin_next;
            wptr <= waddr_bin_next xor shift_right(waddr_bin_next, 1);
        end if;
    end process;

    -- Read-domain binary and registered Gray pointers.
    process (rclk, rrstn)
    begin
        if rrstn = '0' then
            raddr_bin <= (others => '0');
            rptr      <= (others => '0');
        elsif rising_edge(rclk) then
            raddr_bin <= raddr_bin_next;
            rptr <= raddr_bin_next xor shift_right(raddr_bin_next, 1);
        end if;
    end process;

    -- Synchronize the read Gray pointer into the write clock domain.
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

    -- Synchronize the write Gray pointer into the read clock domain.
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

    ram_inst : entity work.dual_port_RAM(rtl)
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
