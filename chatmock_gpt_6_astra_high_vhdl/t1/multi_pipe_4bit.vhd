library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_pipe_4bit is
    generic (
        size : positive := 4
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        mul_a   : in  std_logic_vector(size - 1 downto 0);
        mul_b   : in  std_logic_vector(size - 1 downto 0);
        mul_out : out std_logic_vector(2 * size - 1 downto 0)
    );
end entity multi_pipe_4bit;

architecture rtl of multi_pipe_4bit is
    constant PRODUCT_WIDTH : positive := 2 * size;
    constant PAIR_COUNT    : positive := (size + 1) / 2;

    subtype product_t is unsigned(PRODUCT_WIDTH - 1 downto 0);
    type partial_array_t is array (natural range <>) of product_t;

    signal mul_a_ext       : product_t;
    signal mul_b_ext       : product_t;
    signal partial_product : partial_array_t(0 to size - 1);
    signal sum_reg         : partial_array_t(0 to PAIR_COUNT - 1);
begin
    mul_a_ext <= resize(unsigned(mul_a), PRODUCT_WIDTH);
    mul_b_ext <= resize(unsigned(mul_b), PRODUCT_WIDTH);

    gen_partial_products : for i in 0 to size - 1 generate
    begin
        partial_product(i) <= shift_left(mul_a_ext, i)
                              when mul_b_ext(i) = '1'
                              else (others => '0');
    end generate gen_partial_products;

    -- First register level: pairwise partial-product sums.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            sum_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            for i in 0 to PAIR_COUNT - 1 loop
                if (2 * i + 1) < size then
                    sum_reg(i) <= partial_product(2 * i)
                                + partial_product(2 * i + 1);
                else
                    sum_reg(i) <= partial_product(2 * i);
                end if;
            end loop;
        end if;
    end process;

    -- Second register level: final product.
    process (clk, rst_n)
        variable total : product_t;
    begin
        if rst_n = '0' then
            mul_out <= (others => '0');
        elsif rising_edge(clk) then
            total := (others => '0');
            for i in 0 to PAIR_COUNT - 1 loop
                total := total + sum_reg(i);
            end loop;
            mul_out <= std_logic_vector(total);
        end if;
    end process;
end architecture rtl;
