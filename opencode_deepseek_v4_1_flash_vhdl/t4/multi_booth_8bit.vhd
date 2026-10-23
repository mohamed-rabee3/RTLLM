library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_booth_8bit is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           a : in STD_LOGIC_VECTOR (7 downto 0);
           b : in STD_LOGIC_VECTOR (7 downto 0);
           p : out STD_LOGIC_VECTOR (15 downto 0);
           rdy : out STD_LOGIC);
end multi_booth_8bit;

architecture Behavioral of multi_booth_8bit is
    signal multiplier : std_logic_vector(15 downto 0);
    signal multiplicand : std_logic_vector(15 downto 0);
    signal ctr : unsigned(4 downto 0);
    signal p_reg : unsigned(15 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            multiplier <= (15 downto 8 => a(7)) & a;
            multiplicand <= (15 downto 8 => b(7)) & b;
            p_reg <= (others => '0');
            ctr <= (others => '0');
            rdy <= '0';
        elsif rising_edge(clk) then
            if ctr < 16 then
                multiplicand <= multiplicand(14 downto 0) & '0';
                if multiplier(to_integer(ctr)) = '1' then
                    p_reg <= p_reg + unsigned(multiplicand);
                end if;
                ctr <= ctr + 1;
                rdy <= '0';
            else
                rdy <= '1';
            end if;
        end if;
    end process;

    p <= std_logic_vector(p_reg);
end Behavioral;
