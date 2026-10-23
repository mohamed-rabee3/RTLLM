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
end entity dual_port_RAM;

architecture rtl of dual_port_RAM is
  type ram_type is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
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
  function clog2(n : integer) return integer is
    variable r : integer := 0;
    variable v : integer := 1;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  constant ADDR_WIDTH : integer := clog2(DEPTH);
  constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

  signal waddr_bin : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
  signal raddr_bin : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');

  signal wptr : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal rptr : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

  signal rptr_sync1 : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal rptr_sync2 : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal wptr_sync1 : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');
  signal wptr_sync2 : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

  signal wfull_i  : std_logic;
  signal rempty_i : std_logic;
  signal wen      : std_logic;
  signal ren      : std_logic;

begin
  process(wclk, wrstn)
  begin
    if wrstn = '0' then
      waddr_bin <= (others => '0');
    elsif rising_edge(wclk) then
      if (winc = '1' and wfull_i = '0') then
        waddr_bin <= waddr_bin + 1;
      end if;
    end if;
  end process;

  process(rclk, rrstn)
  begin
    if rrstn = '0' then
      raddr_bin <= (others => '0');
    elsif rising_edge(rclk) then
      if (rinc = '1' and rempty_i = '0') then
        raddr_bin <= raddr_bin + 1;
      end if;
    end if;
  end process;

  wptr <= std_logic_vector(waddr_bin xor shift_right(waddr_bin, 1));
  rptr <= std_logic_vector(raddr_bin xor shift_right(raddr_bin, 1));

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

  wfull_i <= '1' when (wptr = ((not rptr_sync2(PTR_WIDTH-1)) &
                               (not rptr_sync2(PTR_WIDTH-2)) &
                               rptr_sync2(PTR_WIDTH-3 downto 0))) else '0';

  rempty_i <= '1' when (rptr = wptr_sync2) else '0';

  wfull  <= wfull_i;
  rempty <= rempty_i;

  wen <= winc and (not wfull_i);
  ren <= rinc and (not rempty_i);

  u_dual_port_RAM : entity work.dual_port_RAM
    generic map (
      WIDTH      => WIDTH,
      DEPTH      => DEPTH,
      ADDR_WIDTH => ADDR_WIDTH
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
