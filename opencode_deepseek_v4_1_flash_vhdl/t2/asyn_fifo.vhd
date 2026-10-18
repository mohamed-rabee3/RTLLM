library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dual_port_RAM is
  generic (
    DEPTH      : integer := 16;
    WIDTH      : integer := 8;
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
  type RAM_TYPE is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal RAM_MEM : RAM_TYPE := (others => (others => '0'));
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
    DEPTH : integer := 16;
    WIDTH : integer := 8
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

  function clog2 (n : positive) return natural is
    variable res  : natural := 0;
    variable temp : natural := n - 1;
  begin
    while temp > 0 loop
      res  := res + 1;
      temp := temp / 2;
    end loop;
    return res;
  end function;

  constant ADDR_WIDTH : integer := clog2(DEPTH);
  constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

  -- Write domain signals
  signal waddr_bin      : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
  signal waddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);
  signal wptr           : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal wptr_next      : std_logic_vector(PTR_WIDTH-1 downto 0);
  signal wfull_int      : std_logic := '0';
  signal wfull_val      : std_logic;
  signal rptr_syn1      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal rptr_buff      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

  -- Read domain signals
  signal raddr_bin      : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
  signal raddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);
  signal rptr           : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal rptr_next      : std_logic_vector(PTR_WIDTH-1 downto 0);
  signal rempty_int     : std_logic := '1';
  signal rempty_val     : std_logic;
  signal wptr_syn1      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal wptr_buff      : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

  -- RAM control signals
  signal wenc       : std_logic;
  signal renc       : std_logic;
  signal waddr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal raddr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal ram_rdata  : std_logic_vector(WIDTH-1 downto 0);

begin

  -- Write domain process
  process(wclk, wrstn)
  begin
    if wrstn = '0' then
      waddr_bin <= (others => '0');
      wptr      <= (others => '0');
      wfull_int <= '0';
      rptr_syn1 <= (others => '0');
      rptr_buff <= (others => '0');
    elsif rising_edge(wclk) then
      rptr_syn1 <= rptr;
      rptr_buff <= rptr_syn1;
      waddr_bin <= waddr_bin_next;
      wptr      <= wptr_next;
      wfull_int <= wfull_val;
    end if;
  end process;

  -- Read domain process
  process(rclk, rrstn)
  begin
    if rrstn = '0' then
      raddr_bin  <= (others => '0');
      rptr       <= (others => '0');
      rempty_int <= '1';
      wptr_syn1  <= (others => '0');
      wptr_buff  <= (others => '0');
    elsif rising_edge(rclk) then
      wptr_syn1  <= wptr;
      wptr_buff  <= wptr_syn1;
      raddr_bin  <= raddr_bin_next;
      rptr       <= rptr_next;
      rempty_int <= rempty_val;
    end if;
  end process;

  -- Write next-state and full logic
  waddr_bin_next <= waddr_bin + 1 when (winc = '1' and wfull_int = '0') else waddr_bin;
  wptr_next <= std_logic_vector(waddr_bin_next xor shift_right(waddr_bin_next, 1));
  wfull_val <= '1' when wptr_next = ((not rptr_buff(PTR_WIDTH-1)) & (not rptr_buff(PTR_WIDTH-2)) & rptr_buff(PTR_WIDTH-3 downto 0)) else '0';

  -- Read next-state and empty logic
  raddr_bin_next <= raddr_bin + 1 when (rinc = '1' and rempty_int = '0') else raddr_bin;
  rptr_next <= std_logic_vector(raddr_bin_next xor shift_right(raddr_bin_next, 1));
  rempty_val <= '1' when rptr_next = wptr_buff else '0';

  -- RAM interface
  waddr <= std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0));
  raddr <= std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0));
  wenc  <= winc and (not wfull_int);
  renc  <= rinc and (not rempty_int);

  -- Output assignments
  wfull  <= wfull_int;
  rempty <= rempty_int;
  rdata  <= ram_rdata;

  -- Dual-port RAM instantiation
  u_dual_port_RAM : entity work.dual_port_RAM
    generic map (
      DEPTH      => DEPTH,
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
      rdata => ram_rdata
    );

end rtl;
