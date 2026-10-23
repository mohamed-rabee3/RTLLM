library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dual_port_RAM is
    generic (
        WIDTH      : integer := 8;
        DEPTH      : integer := 16;
        ADDR_WIDTH : integer := 4
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
end dual_port_RAM;

architecture rtl of dual_port_RAM is
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
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity asyn_fifo is
    generic (
        WIDTH : integer := 8;
        DEPTH : integer := 16
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
end asyn_fifo;

architecture rtl of asyn_fifo is
    function clog2 (value : integer) return integer is
        variable result : integer := 0;
        variable v      : integer := value - 1;
    begin
        while v > 0 loop
            v := v / 2;
            result := result + 1;
        end loop;
        return result;
    end function;

    constant ADDR_WIDTH : integer := clog2(DEPTH);
    constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

    signal waddr_bin : unsigned(PTR_WIDTH-1 downto 0);
    signal raddr_bin : unsigned(PTR_WIDTH-1 downto 0);
    signal wptr      : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rptr      : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal wptr_sync1, wptr_sync2 : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rptr_sync1, rptr_sync2 : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal wfull_i, rempty_i      : std_logic;
    signal wenc, renc             : std_logic;
    signal waddr, raddr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
begin
    -- Write pointer binary and Gray
    process(wclk, wrstn)
    begin
        if wrstn = '0' then
            waddr_bin <= (others => '0');
            wptr      <= (others => '0');
        elsif rising_edge(wclk) then
            if winc = '1' and wfull_i = '0' then
                waddr_bin <= waddr_bin + 1;
                wptr      <= std_logic_vector((waddr_bin + 1) xor ((waddr_bin + 1) srl 1));
            else
                wptr <= std_logic_vector(waddr_bin xor (waddr_bin srl 1));
            end if;
        end if;
    end process;

    -- Read pointer binary and Gray
    process(rclk, rrstn)
    begin
        if rrstn = '0' then
            raddr_bin <= (others => '0');
            rptr      <= (others => '0');
        elsif rising_edge(rclk) then
            if rinc = '1' and rempty_i = '0' then
                raddr_bin <= raddr_bin + 1;
                rptr      <= std_logic_vector((raddr_bin + 1) xor ((raddr_bin + 1) srl 1));
            else
                rptr <= std_logic_vector(raddr_bin xor (raddr_bin srl 1));
            end if;
        end if;
    end process;

    -- Read pointer synchronizer to write clock
    process(wclk, wrstn)
    begin
        if wrstn = '0' then
            rptr_sync1 <= (others => '0');
            rptr_sync2 <= (others => '0');
        elsif rising_edge(wclk) then
            rptr_sync1 <= rptr;
            rptr_sync2 <= rptr_sync1;
        end if;
    end process;

    -- Write pointer synchronizer to read clock
    process(rclk, rrstn)
    begin
        if rrstn = '0' then
            wptr_sync1 <= (others => '0');
            wptr_sync2 <= (others => '0');
        elsif rising_edge(rclk) then
            wptr_sync1 <= wptr;
            wptr_sync2 <= wptr_sync1;
        end if;
    end process;

    -- Full and empty generation
    wfull_i <= '1' when wptr = (not rptr_sync2(PTR_WIDTH-1)) & (not rptr_sync2(PTR_WIDTH-2)) & rptr_sync2(PTR_WIDTH-3 downto 0) else '0';
    rempty_i <= '1' when rptr = wptr_sync2 else '0';

    wfull  <= wfull_i;
    rempty <= rempty_i;

    -- RAM control signals
    wenc <= winc and (not wfull_i);
    renc <= rinc and (not rempty_i);

    -- RAM addresses (lower ADDR_WIDTH bits)
    waddr <= std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0));
    raddr <= std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0));

    -- Dual-port RAM instantiation
    u_dual_port_RAM : entity work.dual_port_RAM
        generic map (
            WIDTH      => WIDTH,
            DEPTH      => DEPTH,
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
            rdata => rdata
        );

end rtl;
