library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- Dual-port RAM module
-- ============================================================================
entity dual_port_RAM is
  generic (
    DEPTH : integer := 16;
    WIDTH : integer := 8
  );
  port (
    wclk  : in  std_logic;
    wenc  : in  std_logic;
    waddr : in  std_logic_vector;  -- width calculated inside architecture
    wdata : in  std_logic_vector(WIDTH-1 downto 0);
    rclk  : in  std_logic;
    renc  : in  std_logic;
    raddr : in  std_logic_vector;  -- width calculated inside architecture
    rdata : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity dual_port_RAM;

architecture rtl of dual_port_RAM is
  -- function to compute address width
  function clog2 (constant n : integer) return integer is
    variable i : integer := 0;
  begin
    while (2**i < n) loop
      i := i + 1;
    end loop;
    return i;
  end function clog2;

  constant ADDR_WIDTH : integer := clog2(DEPTH);
  type ram_array is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal mem       : ram_array;
  signal rdata_reg : std_logic_vector(WIDTH-1 downto 0);
begin

  -- Write process
  process (wclk)
  begin
    if rising_edge(wclk) then
      if wenc = '1' then
        mem(to_integer(unsigned(waddr(ADDR_WIDTH-1 downto 0)))) <= wdata;
      end if;
    end if;
  end process;

  -- Read process (registered output)
  process (rclk)
  begin
    if rising_edge(rclk) then
      if renc = '1' then
        rdata_reg <= mem(to_integer(unsigned(raddr(ADDR_WIDTH-1 downto 0))));
      end if;
    end if;
  end process;

  rdata <= rdata_reg;

end architecture rtl;


-- ============================================================================
-- Asynchronous FIFO module
-- ============================================================================
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
end entity asyn_fifo;

architecture rtl of asyn_fifo is

  -- --------------------------------------------------------------------------
  -- Constants and functions
  -- --------------------------------------------------------------------------
  function clog2 (constant n : integer) return integer is
    variable i : integer := 0;
  begin
    while (2**i < n) loop
      i := i + 1;
    end loop;
    return i;
  end function clog2;

  constant ADDR_WIDTH : integer := clog2(DEPTH);
  constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

  function gray_encode (bin : unsigned(PTR_WIDTH-1 downto 0)) 
    return std_logic_vector is
  begin
    return std_logic_vector(bin xor 
      ('0' & bin(PTR_WIDTH-1 downto 1)));
  end function gray_encode;

  -- --------------------------------------------------------------------------
  -- Internal signals
  -- --------------------------------------------------------------------------
  signal wbin     : unsigned(PTR_WIDTH-1 downto 0);
  signal rbin     : unsigned(PTR_WIDTH-1 downto 0);
  signal wptr     : std_logic_vector(PTR_WIDTH-1 downto 0);  -- Gray pointer (write domain)
  signal rptr     : std_logic_vector(PTR_WIDTH-1 downto 0);  -- Gray pointer (read domain)
  signal wptr_buff: std_logic_vector(PTR_WIDTH-1 downto 0);  -- first sync FF (read domain)
  signal rptr_buff: std_logic_vector(PTR_WIDTH-1 downto 0);  -- first sync FF (write domain)
  signal wptr_syn : std_logic_vector(PTR_WIDTH-1 downto 0);  -- synchronized write pointer (read domain)
  signal rptr_syn : std_logic_vector(PTR_WIDTH-1 downto 0);  -- synchronized read pointer (write domain)
  signal wfull_i  : std_logic;
  signal rempty_i : std_logic;
  signal waddr    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal raddr    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wen      : std_logic;
  signal ren      : std_logic;

begin

  -- --------------------------------------------------------------------------
  -- Write pointer logic (write clock domain)
  -- --------------------------------------------------------------------------
  process (wclk)
  begin
    if rising_edge(wclk) then
      if wrstn = '0' then
        wbin <= (others => '0');
        wptr <= (others => '0');
      elsif (winc = '1' and wfull_i = '0') then
        wbin <= wbin + 1;
        wptr <= gray_encode(wbin + 1);
      end if;
    end if;
  end process;

  waddr <= std_logic_vector(wbin(ADDR_WIDTH-1 downto 0));

  -- --------------------------------------------------------------------------
  -- Read pointer logic (read clock domain)
  -- --------------------------------------------------------------------------
  process (rclk)
  begin
    if rising_edge(rclk) then
      if rrstn = '0' then
        rbin <= (others => '0');
        rptr <= (others => '0');
      elsif (rinc = '1' and rempty_i = '0') then
        rbin <= rbin + 1;
        rptr <= gray_encode(rbin + 1);
      end if;
    end if;
  end process;

  raddr <= std_logic_vector(rbin(ADDR_WIDTH-1 downto 0));

  -- --------------------------------------------------------------------------
  -- Read pointer synchronizer (two flip-flops in write clock domain)
  -- --------------------------------------------------------------------------
  process (wclk)
  begin
    if rising_edge(wclk) then
      if wrstn = '0' then
        rptr_buff <= (others => '0');
        rptr_syn  <= (others => '0');
      else
        rptr_buff <= rptr;          -- first stage
        rptr_syn  <= rptr_buff;     -- second stage (synchronized output)
      end if;
    end if;
  end process;

  -- --------------------------------------------------------------------------
  -- Write pointer synchronizer (two flip-flops in read clock domain)
  -- --------------------------------------------------------------------------
  process (rclk)
  begin
    if rising_edge(rclk) then
      if rrstn = '0' then
        wptr_buff <= (others => '0');
        wptr_syn  <= (others => '0');
      else
        wptr_buff <= wptr;          -- first stage
        wptr_syn  <= wptr_buff;     -- second stage (synchronized output)
      end if;
    end if;
  end process;

  -- --------------------------------------------------------------------------
  -- Full and empty flag generation (combinational)
  -- --------------------------------------------------------------------------
  wfull_i <= '1' when (wptr = (not rptr_syn(PTR_WIDTH-1 downto PTR_WIDTH-2) &
                               rptr_syn(PTR_WIDTH-3 downto 0)))
                  else '0';

  rempty_i <= '1' when (rptr = wptr_syn) else '0';

  wfull  <= wfull_i;
  rempty <= rempty_i;

  -- --------------------------------------------------------------------------
  -- RAM enable signals (gated by full/empty)
  -- --------------------------------------------------------------------------
  wen <= winc and not wfull_i;
  ren <= rinc and not rempty_i;

  -- --------------------------------------------------------------------------
  -- Dual-port RAM instantiation
  -- --------------------------------------------------------------------------
  dual_port_RAM_inst : entity work.dual_port_RAM
    generic map (
      DEPTH => DEPTH,
      WIDTH => WIDTH
    )
    port map (
      wclk   => wclk,
      wenc   => wen,
      waddr  => waddr,
      wdata  => wdata,
      rclk   => rclk,
      renc   => ren,
      raddr  => raddr,
      rdata  => rdata
    );

end architecture rtl;