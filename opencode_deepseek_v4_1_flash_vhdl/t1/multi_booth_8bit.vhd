library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_booth_8bit is
    Port ( clk   : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           a     : in  STD_LOGIC_VECTOR (7 downto 0);
           b     : in  STD_LOGIC_VECTOR (7 downto 0);
           p     : out STD_LOGIC_VECTOR (15 downto 0);
           rdy   : out STD_LOGIC);
end multi_booth_8bit;

architecture Behavioral of multi_booth_8bit is
    signal multiplier   : signed(15 downto 0);
    signal multiplicand : signed(15 downto 0);
    signal p_reg        : signed(15 downto 0);
    signal ctr          : unsigned(4 downto 0);
    signal rdy_reg      : std_logic;
begin

    p   <= std_logic_vector(p_reg);
    rdy <= rdy_reg;

    process(clk, reset)
    begin
        if reset = '1' then
            multiplier   <= resize(signed(a), 16);
            multiplicand <= resize(signed(b), 16);
            p_reg        <= (others => '0');
            ctr          <= (others => '0');
            rdy_reg      <= '0';
        elsif rising_edge(clk) then
            if ctr < 16 then
                multiplicand <= shift_left(multiplicand, 1);
                if multiplier(to_integer(ctr)) = '1' then
                    p_reg <= p_reg + multiplicand;
                end if;
                ctr <= ctr + 1;
                if ctr = 15 then
                    rdy_reg <= '1';
                end if;
            else
                rdy_reg <= '1';
            end if;
        end if;
    end process;

end Behavioral;
