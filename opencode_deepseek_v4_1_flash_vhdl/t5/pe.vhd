library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pe is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        a : in STD_LOGIC_VECTOR (31 downto 0);
        b : in STD_LOGIC_VECTOR (31 downto 0);
        c : out STD_LOGIC_VECTOR (31 downto 0)
    );
end pe;

architecture Behavioral of pe is
    signal c_reg : STD_LOGIC_VECTOR(31 downto 0);
begin
    process(clk, rst)
        variable product : unsigned(63 downto 0);
        variable sum : unsigned(63 downto 0);
    begin
        if rst = '1' then
            c_reg <= (others => '0');
        elsif rising_edge(clk) then
            product := unsigned(a) * unsigned(b);
            sum := resize(unsigned(c_reg), 64) + product;
            c_reg <= std_logic_vector(resize(sum, 32));
        end if;
    end process;

    c <= c_reg;
end Behavioral;
