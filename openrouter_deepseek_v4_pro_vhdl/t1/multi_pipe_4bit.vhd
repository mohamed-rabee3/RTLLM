library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_pipe_4bit is
  generic (
    size : positive := 4       -- Parameter: size = 4
  );
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;   -- Active-low reset
    mul_a   : in  std_logic_vector(size-1 downto 0);
    mul_b   : in  std_logic_vector(size-1 downto 0);
    mul_out : out std_logic_vector(2*size-1 downto 0)
  );
end entity multi_pipe_4bit;

architecture rtl of multi_pipe_4bit is
  constant width : integer := 2 * size;   -- 8

  -- Extended input signals (size zero bits added at MSB)
  signal mul_a_ext : unsigned(width-1 downto 0);
  signal mul_b_ext : unsigned(width-1 downto 0);

  -- Partial products array
  type pp_array is array (0 to size-1) of unsigned(width-1 downto 0);
  signal pp : pp_array;

  -- Intermediate sum registers (first pipeline stage)
  signal sum01, sum23 : unsigned(width-1 downto 0);
begin

  -- Extension: pad MSB with zeros
  mul_a_ext <= resize(unsigned(mul_a), width);
  mul_b_ext <= resize(unsigned(mul_b), width);

  -- Generate partial products for each bit of the multiplier
  gen_pp : for i in 0 to size-1 generate
    pp(i) <= shift_left(mul_a_ext, i) when mul_b(i) = '1' else
             (others => '0');
  end generate;

  -- First pipeline stage: register the sum of partial product pairs
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      sum01 <= (others => '0');
      sum23 <= (others => '0');
    elsif rising_edge(clk) then
      sum01 <= pp(0) + pp(1);
      sum23 <= pp(2) + pp(3);
    end if;
  end process;

  -- Second pipeline stage: final product calculation and output register
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      mul_out <= (others => '0');
    elsif rising_edge(clk) then
      mul_out <= std_logic_vector(sum01 + sum23);
    end if;
  end process;

end architecture rtl;