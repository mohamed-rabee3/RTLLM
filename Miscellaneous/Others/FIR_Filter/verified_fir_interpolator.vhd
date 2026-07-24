library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_fir_interpolator is
    port(clk       : in  std_logic;
         rst       : in  std_logic;
         valid_in  : in  std_logic;
         data_in   : in  std_logic_vector(15 downto 0);
         valid_out : out std_logic;
         data_out  : out std_logic_vector(15 downto 0));
end verified_fir_interpolator;
architecture rtl of verified_fir_interpolator is
    constant H0 : signed(15 downto 0) := x"0040";
    constant H1 : signed(15 downto 0) := x"0080";
    constant H2 : signed(15 downto 0) := x"0080";
    constant H3 : signed(15 downto 0) := x"0040";
    signal x1, x2, x3 : signed(15 downto 0) := (others => '0');
begin
    process(clk)
        variable acc : signed(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                x1 <= (others => '0'); x2 <= (others => '0'); x3 <= (others => '0');
                data_out  <= (others => '0');
                valid_out <= '0';
            elsif valid_in = '1' then
                acc := H0*signed(data_in) + H1*x1 + H2*x2 + H3*x3;
                data_out  <= std_logic_vector(acc(23 downto 8));  -- acc >>> 8, low 16 bits
                valid_out <= '1';
                x1 <= signed(data_in);
                x2 <= x1;
                x3 <= x2;
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
end rtl;
