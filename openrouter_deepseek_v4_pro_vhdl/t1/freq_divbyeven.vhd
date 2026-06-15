library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_diveven is
  generic (
    NUM_DIV : integer := 2  -- even division factor, must be >= 2
  );
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;  -- active-low reset
    clk_div : out std_logic   -- divided clock output
  );
end entity freq_diveven;

architecture rtl of freq_diveven is

  -- Limit for the counter: toggle every NUM_DIV/2 cycles
  constant LIMIT      : integer := NUM_DIV / 2 - 1;
  constant LIMIT_UNS  : unsigned(3 downto 0) := to_unsigned(LIMIT, 4);

  -- 4-bit counter register
  signal cnt          : unsigned(3 downto 0);

  -- Embedded assertions to validate the generic parameters
begin
  -- Synthesis-friendly assertion statements (evaluated only at elaboration/initialization)
  assert (NUM_DIV mod 2 = 0)
    report "freq_diveven: NUM_DIV must be an even number."
    severity failure;
  assert (LIMIT <= 15)
    report "freq_diveven: NUM_DIV is too large for the 4-bit counter (max 32)."
    severity failure;

  -- Main clock division process
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      cnt     <= (others => '0');
      clk_div <= '0';
    elsif rising_edge(clk) then
      if cnt < LIMIT_UNS then
        -- Not yet at toggle point, just increment
        cnt <= cnt + 1;
        -- clk_div remains unchanged (implicit)
      else
        -- Counter reached the limit: reset and toggle output
        cnt     <= (others => '0');
        clk_div <= not clk_div;
      end if;
    end if;
  end process;

end architecture rtl;