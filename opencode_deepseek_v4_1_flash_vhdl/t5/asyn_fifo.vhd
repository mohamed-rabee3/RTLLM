library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package async_fifo_pkg is
  function clog2(n : integer) return integer;
end package async_fifo_pkg;

package body async_fifo_pkg is
  function clog2(n : integer) return integer is
    variable res : integer := 0;
    variable temp : integer := n - 1;
  begin
    while temp > 0 loop
      res := res + 1;
      temp := temp / 2;
    end loop;
    return res;
  end function clog2;
end package body async_fifo_pkg;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.async_fifo_pkg.ALL;

entity dual_port_RAM is
  generic (
    WIDTH : integer := 8;
    DEPTH : integer := 16
  );
  port (
    wclk  : in std_logic;
    wenc  : in std_logic;
    waddr : in std_logic_vector(clog2(DEPTH)-1 downto 0);
    wdata : in std_logic_vector(WIDTH-1 downto 0);
    rclk  : in std_logic;
    renc  : in std_logic;
    raddr : in std_logic_vector(clog2(DEPTH)-1 downto 0);
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
use work.async_fifo_pkg.ALL;

entity asyn_fifo is
  generic (
    WIDTH : integer := 8;
    DEPTH : integer := 16
  );
  port (
    wclk   : in std_logic;
    rclk   : in std_logic;
    wrstn  : in std_logic;
    rrstn  : in std_logic;
    winc   : in std_logic;
    rinc   : in std_logic;
    wdata  : in std_logic_vector(WIDTH-1 downto 0);
    wfull  : out std_logic;
    rempty : out std_logic;
    rdata  : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity asyn_fifo;

architecture rtl of asyn_fifo is
  constant ADDR_WIDTH : integer := clog2(DEPTH);
  constant PTR_WIDTH  : integer := ADDR_WIDTH + 1;

  signal waddr_bin, raddr_bin : unsigned(PTR_WIDTH-1 downto 0);
  signal wptr, rptr           : std_logic_vector(PTR_WIDTH-1 downto 0);
  signal wptr_buff, wptr_syn  : std_logic_vector(PTR_WIDTH-1 downto 0);
  signal rptr_buff, rptr_syn  : std_logic_vector(PTR_WIDTH-1 downto 0);
  signal waddr, raddr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wen, ren             : std_logic;
  signal wfull_int, rempty_int : std_logic;

  constant FULL_MASK : std_logic_vector(PTR_WIDTH-1 downto 0) := (PTR_WIDTH-1 downto PTR_WIDTH-2 => '1', others => '0');

  function bin2gray(bin : unsigned) return std_logic_vector is
    variable gray : unsigned(bin'range);
  begin
    gray := bin xor shift_right(bin, 1);
    return std_logic_vector(gray);
  end function bin2gray;

begin
  -- Write pointer update
  process(wclk, wrstn)
    variable waddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);
  begin
    if wrstn = '0' then
      waddr_bin <= (others => '0');
      wptr <= (others => '0');
    elsif rising_edge(wclk) then
      if wen = '1' then
        waddr_bin_next := waddr_bin + 1;
        waddr_bin <= waddr_bin_next;
        wptr <= bin2gray(waddr_bin_next);
      end if;
    end if;
  end process;

  -- Read pointer update
  process(rclk, rrstn)
    variable raddr_bin_next : unsigned(PTR_WIDTH-1 downto 0);
  begin
    if rrstn = '0' then
      raddr_bin <= (others => '0');
      rptr <= (others => '0');
    elsif rising_edge(rclk) then
      if ren = '1' then
        raddr_bin_next := raddr_bin + 1;
        raddr_bin <= raddr_bin_next;
        rptr <= bin2gray(raddr_bin_next);
      end if;
    end if;
  end process;

  -- Read pointer synchronizer (to write clock domain)
  process(wclk, wrstn)
  begin
    if wrstn = '0' then
      rptr_buff <= (others => '0');
      rptr_syn <= (others => '0');
    elsif rising_edge(wclk) then
      rptr_buff <= rptr;
      rptr_syn <= rptr_buff;
    end if;
  end process;

  -- Write pointer synchronizer (to read clock domain)
  process(rclk, rrstn)
  begin
    if rrstn = '0' then
      wptr_buff <= (others => '0');
      wptr_syn <= (others => '0');
    elsif rising_edge(rclk) then
      wptr_buff <= wptr;
      wptr_syn <= wptr_buff;
    end if;
  end process;

  -- Full and empty generation
  wfull_int <= '1' when wptr = (rptr_syn xor FULL_MASK) else '0';
  rempty_int <= '1' when rptr = wptr_syn else '0';

  wfull <= wfull_int;
  rempty <= rempty_int;

  -- Control signals
  wen <= winc and (not wfull_int);
  ren <= rinc and (not rempty_int);

  -- Address to RAM
  waddr <= std_logic_vector(waddr_bin(ADDR_WIDTH-1 downto 0));
  raddr <= std_logic_vector(raddr_bin(ADDR_WIDTH-1 downto 0));

  -- Dual-port RAM instantiation
  u_dual_port_RAM : entity work.dual_port_RAM
    generic map (
      WIDTH => WIDTH,
      DEPTH => DEPTH
    )
    port map (
      wclk  => wclk,
      wenc  => wen,
      waddr => waddr,
      wdata => wdata,
      rclk  => rclk,
      renc  => ren,
      raddr => raddr,
      rdata => rdata
    );
end architecture rtl;
