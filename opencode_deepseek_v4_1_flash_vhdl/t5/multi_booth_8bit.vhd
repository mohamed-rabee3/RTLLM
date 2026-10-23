library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_booth_8bit is
    Port (
        clk   : in  std_logic;
        reset : in  std_logic;
        a     : in  std_logic_vector(7 downto 0);
        b     : in  std_logic_vector(7 downto 0);
        p     : out std_logic_vector(15 downto 0);
        rdy   : out std_logic
    );
end multi_booth_8bit;

architecture Behavioral of multi_booth_8bit is
    signal multiplier   : std_logic_vector(15 downto 0);
    signal multiplicand : std_logic_vector(15 downto 0);
    signal product_reg  : std_logic_vector(15 downto 0);
    signal ctr          : unsigned(4 downto 0);
    signal rdy_reg      : std_logic;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            multiplier(15 downto 8) <= (others => a(7));
            multiplier(7 downto 0)  <= a;
            multiplicand(15 downto 8) <= (others => b(7));
            multiplicand(7 downto 0)  <= b;
            product_reg <= (others => '0');
            ctr <= (others => '0');
            rdy_reg <= '0';
        elsif rising_edge(clk) then
            if ctr < 16 then
                multiplicand <= multiplicand(14 downto 0) & '0';
                if multiplier(to_integer(ctr)) = '1' then
                    product_reg <= std_logic_vector(unsigned(product_reg) + unsigned(multiplicand));
                end if;
                ctr <= ctr + 1;
            else
                rdy_reg <= '1';
            end if;
        end if;
    end process;

    p <= product_reg;
    rdy <= rdy_reg;

end Behavioral;
