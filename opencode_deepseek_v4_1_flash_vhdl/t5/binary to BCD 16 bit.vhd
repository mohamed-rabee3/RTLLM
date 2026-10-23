library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2bcd_array is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    valid_in  : in  std_logic;
    binary_in : in  std_logic_vector(15 downto 0);
    bcd_out   : out std_logic_vector(19 downto 0);
    valid_out : out std_logic
  );
end entity bin2bcd_array;

architecture rtl of bin2bcd_array is
  function bin_to_bcd(bin : std_logic_vector(15 downto 0)) return std_logic_vector is
    variable bcd : unsigned(19 downto 0) := (others => '0');
    variable nib : unsigned(3 downto 0);
  begin
    for i in 0 to 15 loop
      nib := bcd(3 downto 0);
      if nib >= 5 then
        bcd(3 downto 0) := nib + 3;
      end if;

      nib := bcd(7 downto 4);
      if nib >= 5 then
        bcd(7 downto 4) := nib + 3;
      end if;

      nib := bcd(11 downto 8);
      if nib >= 5 then
        bcd(11 downto 8) := nib + 3;
      end if;

      nib := bcd(15 downto 12);
      if nib >= 5 then
        bcd(15 downto 12) := nib + 3;
      end if;

      nib := bcd(19 downto 16);
      if nib >= 5 then
        bcd(19 downto 16) := nib + 3;
      end if;

      bcd := bcd(18 downto 0) & bin(15 - i);
    end loop;

    return std_logic_vector(bcd);
  end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        bcd_out   <= (others => '0');
        valid_out <= '0';
      else
        valid_out <= valid_in;
        if valid_in = '1' then
          bcd_out <= bin_to_bcd(binary_in);
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
