library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_booth_8bit is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        a     : in  std_logic_vector(7 downto 0);
        b     : in  std_logic_vector(7 downto 0);
        p     : out std_logic_vector(15 downto 0);
        rdy   : out std_logic
    );
end entity multi_booth_8bit;

architecture rtl of multi_booth_8bit is
    signal multiplier   : unsigned(15 downto 0);
    signal multiplicand : unsigned(15 downto 0);
    signal product_reg  : unsigned(15 downto 0);
    signal ctr          : unsigned(4 downto 0);
begin
    p <= std_logic_vector(product_reg);

    process (clk, reset)
    begin
        if reset = '1' then
            multiplier   <= unsigned(resize(signed(a), 16));
            multiplicand <= unsigned(resize(signed(b), 16));
            product_reg  <= (others => '0');
            ctr          <= (others => '0');
            rdy          <= '0';
        elsif rising_edge(clk) then
            if ctr < to_unsigned(16, ctr'length) then
                if multiplier(to_integer(ctr)) = '1' then
                    product_reg <= product_reg + multiplicand;
                end if;

                multiplicand <= shift_left(multiplicand, 1);
                ctr          <= ctr + 1;
                rdy          <= '0';
            else
                rdy <= '1';
            end if;
        end if;
    end process;
end architecture rtl;
