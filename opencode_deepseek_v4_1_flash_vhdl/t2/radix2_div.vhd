library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity radix2_div is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    sign      : in  std_logic;
    dividend  : in  std_logic_vector(7 downto 0);
    divisor   : in  std_logic_vector(7 downto 0);
    opn_valid : in  std_logic;
    res_valid : out std_logic;
    result    : out std_logic_vector(15 downto 0)
  );
end radix2_div;

architecture rtl of radix2_div is
  signal SR          : unsigned(15 downto 0);
  signal NEG_DIVISOR : unsigned(7 downto 0);
  signal cnt         : unsigned(3 downto 0);
  signal start_cnt   : std_logic;
  signal sign_reg    : std_logic;
  signal dividend_neg: std_logic;
  signal divisor_neg : std_logic;
  signal res_valid_reg: std_logic;
  signal result_reg  : std_logic_vector(15 downto 0);
begin

  process(clk, rst)
    variable abs_dividend : unsigned(7 downto 0);
    variable abs_divisor  : unsigned(7 downto 0);
    variable shifted      : unsigned(15 downto 0);
    variable sum          : unsigned(8 downto 0);
    variable carry        : std_logic;
    variable new_upper    : unsigned(7 downto 0);
    variable new_SR       : unsigned(15 downto 0);
    variable rem_abs      : unsigned(7 downto 0);
    variable quot_abs     : unsigned(7 downto 0);
    variable rem_out      : unsigned(7 downto 0);
    variable quot_out     : unsigned(7 downto 0);
  begin
    if rst = '1' then
      SR           <= (others => '0');
      NEG_DIVISOR  <= (others => '0');
      cnt          <= (others => '0');
      start_cnt    <= '0';
      sign_reg     <= '0';
      dividend_neg <= '0';
      divisor_neg  <= '0';
      res_valid_reg<= '0';
      result_reg   <= (others => '0');
    elsif rising_edge(clk) then
      if (opn_valid = '1' and res_valid_reg = '0' and start_cnt = '0') then
        -- Start a new operation
        abs_dividend := unsigned(dividend);
        abs_divisor  := unsigned(divisor);
        if sign = '1' then
          if dividend(7) = '1' then
            abs_dividend := (not abs_dividend) + 1;
          end if;
          if divisor(7) = '1' then
            abs_divisor := (not abs_divisor) + 1;
          end if;
          dividend_neg <= dividend(7);
          divisor_neg  <= divisor(7);
        else
          dividend_neg <= '0';
          divisor_neg  <= '0';
        end if;
        sign_reg <= sign;
        SR <= resize(abs_dividend, 16);
        NEG_DIVISOR <= (not abs_divisor) + 1;
        cnt <= to_unsigned(1, 4);
        start_cnt <= '1';
        res_valid_reg <= '0';
      elsif start_cnt = '1' then
        -- Perform one division step
        shifted := shift_left(SR, 1);
        sum := resize(shifted(15 downto 8), 9) + resize(NEG_DIVISOR, 9);
        carry := sum(8);
        if carry = '1' then
          new_upper := sum(7 downto 0);
        else
          new_upper := shifted(15 downto 8);
        end if;
        new_SR := new_upper & shifted(7 downto 1) & carry;
        SR <= new_SR;

        if cnt = 8 then
          -- Division complete
          start_cnt <= '0';
          cnt <= (others => '0');
          rem_abs  := new_SR(15 downto 8);
          quot_abs := new_SR(7 downto 0);
          if sign_reg = '1' then
            if dividend_neg = '1' then
              rem_out := (not rem_abs) + 1;
            else
              rem_out := rem_abs;
            end if;
            if (dividend_neg xor divisor_neg) = '1' then
              quot_out := (not quot_abs) + 1;
            else
              quot_out := quot_abs;
            end if;
          else
            rem_out  := rem_abs;
            quot_out := quot_abs;
          end if;
          result_reg <= std_logic_vector(rem_out & quot_out);
          res_valid_reg <= '1';
        else
          cnt <= cnt + 1;
        end if;
      elsif opn_valid = '0' then
        res_valid_reg <= '0';
      end if;
    end if;
  end process;

  res_valid <= res_valid_reg;
  result <= result_reg;

end rtl;
