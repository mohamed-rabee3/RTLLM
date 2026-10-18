library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package asyn_fifo_pkg is
    function clog2(n : positive) return positive;
end package asyn_fifo_pkg;

package body asyn_fifo_pkg is
    function clog2(n : positive) return positive is
        variable value : natural := n - 1;
        variable bits  : natural := 0;
    begin
        while value > 0 loop
            value := value / 2;
            bits  := bits + 1;
        end loop;
        if bits = 0 then
            return 1;
        end if;
        return bits;
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
    process(wclk)
    begin
        if rising_edge(wclk) then
            if wenc = '1' then
                RAM_MEM(to_integer(unsigned(waddr))) <= wdata;
            end if;
        end if;
    end process;

    process(rclk)
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
    constant ADDR_WIDTH : positive := clog2(DEPTH);

    subtype pointer_type is unsigned(ADDR_WIDTH downto 0);

    signal waddr_bin : pointer_type;
    signal raddr_bin : pointer_type;
    signal wptr     : pointer_type;
    signal rptr     : pointer_type;

    signal rptr_buff : pointer_type;
    signal rptr_syn  : pointer_type;
    signal wptr_buff : pointer_type;
    signal wptr_syn  : pointer_type;

    signal full_target : pointer_type;
    signal wfull_i     : std_logic;
    signal rempty_i    : std_logic;
    signal wen         : std_logic;
    signal ren         : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of rptr_buff : signal is "TRUE";
    attribute ASYNC_REG of rptr_syn  : signal is "TRUE";
    attribute ASYNC_REG of wptr_buff : signal is "TRUE";
    attribute ASYNC_REG of wptr_syn  : signal is "TRUE";

    function binary_to_gray(value : pointer_type) return pointer_type is
    begin
        return value xor shift_right(value, 1);
    end function;

    function invert_top_two(value : pointer_type) return pointer_type is
        variable result : pointer_type;
    begin
        result := value;
        result(ADDR_WIDTH)   := not value(ADDR_WIDTH);
        result(ADDR_WIDTH-1) := not value(ADDR_WIDTH-1);
        return result;
    end function;
begin
    assert DEPTH >= 2 and DEPTH = 2**ADDR_WIDTH
        report "asyn_fifo: DEPTH must be a power of two and at least 2"
        severity failure;

    full_target <= invert_top_two(rptr_syn);

    wfull_i  <= '1' when wptr = full_target else '0';
    rempty_i <= '1' when rptr = wptr_syn else '0';

    wfull  <= wfull_i;
    rempty <= rempty_i;

    wen <= winc and not wfull_i and wrstn;
    ren <= rinc and not rempty_i and rrstn;

    process(wclk, wrstn)
        variable next_binary : pointer_type;
    begin
        if wrstn = '0' then
            waddr_bin <= (others => '0');
            wptr      <= (others => '0');
        elsif rising_edge(wclk) then
            if wen = '1' then
                next_binary := waddr_bin + 1;
                waddr_bin   <= next_binary;
                wptr        <= binary_to_gray(next_binary);
            end if;
        end if;
    end process;

    process(rclk, rrstn)
        variable next_binary : pointer_type;
    begin
        if rrstn = '0' then
            raddr_bin <= (others => '0');
            rptr      <= (others => '0');
        elsif rising_edge(rclk) then
            if ren = '1' then
                next_binary := raddr_bin + 1;
                raddr_bin   <= next_binary;
                rptr        <= binary_to_gray(next_binary);
            end if;
        end if;
    end process;

    process(wclk, wrstn)
    begin
        if wrstn = '0' then
            rptr_buff <= (others => '0');
            rptr_syn  <= (others => '0');
        elsif rising_edge(wclk) then
            rptr_buff <= rptr;
            rptr_syn  <= rptr_buff;
        end if;
    end process;

    process(rclk, rrstn)
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
