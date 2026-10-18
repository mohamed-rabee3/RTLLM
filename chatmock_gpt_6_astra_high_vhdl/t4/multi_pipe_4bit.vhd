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
    constant SUM_COUNT     : positive := (size + 1) / 2;

    subtype product_t is unsigned(PRODUCT_WIDTH - 1 downto 0);
    type product_array_t is array (natural range <>) of product_t;

    signal a_extended       : product_t;
    signal b_extended       : product_t;
    signal partial_products : product_array_t(0 to size - 1);
    signal sum_registers    : product_array_t(0 to SUM_COUNT - 1);
begin
    a_extended <= resize(unsigned(mul_a), PRODUCT_WIDTH);
    b_extended <= resize(unsigned(mul_b), PRODUCT_WIDTH);

    gen_partial_products : for i in 0 to size - 1 generate
    begin
        partial_products(i) <= shift_left(a_extended, i)
                               when b_extended(i) = '1'
                               else (others => '0');
    end generate gen_partial_products;

    gen_sum_registers : for i in 0 to SUM_COUNT - 1 generate
    begin
        gen_pair : if (2 * i + 1) < size generate
        begin
            process (clk, rst_n)
            begin
                if rst_n = '0' then
                    sum_registers(i) <= (others => '0');
                elsif rising_edge(clk) then
                    sum_registers(i) <= partial_products(2 * i)
                                      + partial_products(2 * i + 1);
                end if;
            end process;
        end generate gen_pair;

        gen_unpaired : if (2 * i + 1) >= size generate
        begin
            process (clk, rst_n)
            begin
                if rst_n = '0' then
                    sum_registers(i) <= (others => '0');
                elsif rising_edge(clk) then
                    sum_registers(i) <= partial_products(2 * i);
                end if;
            end process;
        end generate gen_unpaired;
    end generate gen_sum_registers;

    process (clk, rst_n)
        variable total : product_t;
    begin
        if rst_n = '0' then
            mul_out <= (others => '0');
        elsif rising_edge(clk) then
            total := (others => '0');
            for i in 0 to SUM_COUNT - 1 loop
                total := total + sum_registers(i);
            end loop;
            mul_out <= std_logic_vector(total);
        end if;
    end process;
end architecture rtl;
