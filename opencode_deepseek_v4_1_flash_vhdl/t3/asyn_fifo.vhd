library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_RAM is
    generic (
        WIDTH      : positive := 8;
        ADDR_WIDTH : positive := 4
    );
    port (
        wclk  : in  std_logic;
        wenc  : in  std_logic;
        waddr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        wdata : in  std_logic_vector(WIDTH-1 downto 0);
        rclk  : in  std_logic;
        renc  : in  std_logic;
        raddr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        rdata : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity dual_port_RAM;

architecture rtl of dual_port_RAM is
    constant DEPTH : integer := 2**ADDR_WIDTH;
    type ram_type is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal RAM_MEM : ram_type := (others => (others => '0'));
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

entity asyn_fifo is
    generic (
        WIDTH : positive := 8;
        DEPTH : positive := 16
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
    function clog2(n : positive) return natural is
        variable res : natural := 0;
        variable v   : positive := n - 1;
    begin
        while v > 0 loop
            res := res + 1;
            v := v / 2;
        end loop;
        return res;
    end function;

    function bin_to_gray(b : unsigned) return std_logic_vector is
        variable g : unsigned(b'range);
    begin
        g := b xor shift_right(b, 1);
        return std_logic_vector(g);
    end function;

    constant ADDR_WIDTH : integer := clog2(DEPTH);
    constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

    signal waddr_bin : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
    signal raddr_bin : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
    signal wptr      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
    signal rptr      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

    signal wptr_buff : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
    signal wptr_syn  : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
    signal rptr_buff : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
    signal rptr_syn  : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

    signal wfull_int  : std_logic := '0';
    signal rempty_int : std_logic := '1';
    signal wenc       : std_logic;
    signal renc       : std_logic;
    signal waddr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal raddr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal full_compare : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rdata_int  : std_logic_vector(WIDTH-1 downto 0);
begin
    process(wclk, wrstn)
    begin
        if wrstn = '0' then
            waddr_bin <= (others => '0');
            wptr      <= (others => '0');
        elsif rising_edge(wclk) then
            if (winc = '1' and wfull_int = '0') then
                waddr_bin <= waddr_bin + 1;
                wptr      <= bin_to_gray(waddr_bin + 1);
            end if;
        end if;
    end process;

    process(rclk, rrstn)
    begin
        if rrstn = '0' then
            raddr_bin <= (others => '0');
            rptr      <= (others => '0');
        elsif rising_edge(rclk) then
            if (rinc = '1' and rempty_int = '0') then
                raddr_bin <= raddr_bin + 1;
                rptr      <= bin_to_gray(raddr_bin + 1);
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

    full_compare <= (not rptr_syn(PTR_WIDTH-1)) &
                    (not rptr_syn(PTR_WIDTH-2)) &
                    rptr_syn(PTR_WIDTH-3 downto 0);

    wfull_int  <= '1' when (wptr = full_compare) else '0';
    rempty_int <= '1' when (rptr = wptr_syn) else '0';

    wfull  <= wfull_int;
    rempty <= rempty_int;

    wenc <= winc and (not wfull_int);
    renc <= rinc and (not rempty_int);

    waddr <= std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0));
    raddr <= std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0));

    u_dual_port_RAM : entity work.dual_port_RAM(rtl)
        generic map (
            WIDTH      => WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            wclk  => wclk,
            wenc  => wenc,
            waddr => waddr,
            wdata => wdata,
            rclk  => rclk,
            renc  => renc,
            raddr => raddr,
            rdata => rdata_int
        );

    rdata <= rdata_int;

end architecture rtl;
