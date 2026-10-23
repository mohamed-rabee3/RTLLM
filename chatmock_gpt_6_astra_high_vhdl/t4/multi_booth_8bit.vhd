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
    signal multiplier   : signed(15 downto 0);
    signal multiplicand : signed(15 downto 0);
    signal product_reg  : signed(15 downto 0);
    signal ctr          : unsigned(4 downto 0);
    signal ready_reg    : std_logic;
begin
    p   <= std_logic_vector(product_reg);
    rdy <= ready_reg;

    process (clk, reset)
    begin
        if reset = '1' then
            multiplier   <= resize(signed(a), 16);
            multiplicand <= resize(signed(b), 16);
            product_reg  <= (others => '0');
            ctr          <= (others => '0');
            ready_reg    <= '0';
        elsif rising_edge(clk) then
            if ctr < to_unsigned(16, ctr'length) then
                multiplicand <= shift_left(multiplicand, 1);

                if multiplier(to_integer(ctr)) = '1' then
                    product_reg <= product_reg + multiplicand;
                end if;

                ctr       <= ctr + to_unsigned(1, ctr'length);
                ready_reg <= '0';
            else
                ready_reg <= '1';
            end if;
        end if;
    end process;
end architecture rtl;
