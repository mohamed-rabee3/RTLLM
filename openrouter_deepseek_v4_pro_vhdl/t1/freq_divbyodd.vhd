library ieee;
use ieee.std_logic_1164.all;

entity freq_divbyodd is
  generic (
    NUM_DIV : integer := 5    -- Odd division factor
  );
  port (
    clk     : in  std_logic;   -- Input clock
    rst_n   : in  std_logic;   -- Active-low reset
    clk_div : out std_logic    -- Divided output clock
  );
end entity freq_divbyodd;

architecture rtl of freq_divbyodd is

  -- Half of the division factor (integer division, valid for odd NUM_DIV)
  constant HALF : integer := NUM_DIV / 2;

  -- Counters track rising (cnt1) and falling (cnt2) edges
  signal cnt1, cnt2 : integer range 0 to NUM_DIV - 1;

  -- Internal divided clock signals for positive and negative edges
  signal clk_div1, clk_div2 : std_logic;

begin

  -- Process for rising edge of clk
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt1     <= 0;
      clk_div1 <= '0';
    elsif rising_edge(clk) then
      -- Counter rolls over after NUM_DIV - 1
      if cnt1 = NUM_DIV - 1 then
        cnt1 <= 0;
      else
        cnt1 <= cnt1 + 1;
      end if;

      -- Toggle clk_div1 at 0 and at half of NUM_DIV
      if cnt1 = 0 then
        clk_div1 <= not clk_div1;
      elsif cnt1 = HALF then
        clk_div1 <= not clk_div1;
      end if;
    end if;
  end process;

  -- Process for falling edge of clk
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt2     <= 0;
      clk_div2 <= '0';
    elsif falling_edge(clk) then
      -- Counter rolls over after NUM_DIV - 1
      if cnt2 = NUM_DIV - 1 then
        cnt2 <= 0;
      else
        cnt2 <= cnt2 + 1;
      end if;

      -- Toggle clk_div2 at 0 and at half of NUM_DIV
      if cnt2 = 0 then
        clk_div2 <= not clk_div2;
      elsif cnt2 = HALF then
        clk_div2 <= not clk_div2;
      end if;
    end if;
  end process;

  -- Final output is the OR of the two divided clocks
  clk_div <= clk_div1 or clk_div2;

end architecture rtl;