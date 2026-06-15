library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture behavioral of multi_booth_8bit is

    -- Internal registers as 16-bit unsigned vectors.
    signal multiplier_reg   : unsigned(15 downto 0);
    signal multiplicand_reg : unsigned(15 downto 0);
    signal product_reg      : unsigned(15 downto 0);
    signal ctr              : unsigned(4 downto 0);   -- 5-bit counter
    signal rdy_reg          : std_logic;

begin

    -- Output assignments
    p   <= std_logic_vector(product_reg);
    rdy <= rdy_reg;

    -- Asynchronous reset, synchronous operation
    process(clk, reset)
        variable idx : integer range 0 to 15;
    begin
        if reset = '1' then
            -- Reset: load sign-extended a into multiplier_reg,
            -- sign-extended b into multiplicand_reg
            multiplier_reg   <= unsigned(resize(signed(a), 16));
            multiplicand_reg <= unsigned(resize(signed(b), 16));
            product_reg      <= (others => '0');
            ctr              <= (others => '0');
            rdy_reg          <= '0';

        elsif rising_edge(clk) then
            if ctr < 16 then
                idx := to_integer(ctr);
                -- If current bit is '1', accumulate multiplicand
                if multiplier_reg(idx) = '1' then
                    product_reg <= product_reg + multiplicand_reg;
                end if;
                -- Left-shift multiplicand for next iteration
                multiplicand_reg <= multiplicand_reg(14 downto 0) & '0';
                -- Increment counter
                ctr <= ctr + 1;
                -- On the last active cycle (ctr = 15) set ready
                if ctr = 15 then
                    rdy_reg <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture behavioral;