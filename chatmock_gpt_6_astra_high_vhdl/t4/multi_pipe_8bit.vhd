library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_pipe_8bit is
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        mul_en_in  : in  std_logic;
        mul_a      : in  std_logic_vector(7 downto 0);
        mul_b      : in  std_logic_vector(7 downto 0);
        mul_en_out : out std_logic;
        mul_out    : out std_logic_vector(15 downto 0)
    );
end entity multi_pipe_8bit;

architecture rtl of multi_pipe_8bit is
    type partial_product_array is array (0 to 7) of unsigned(15 downto 0);
    type partial_sum_array is array (0 to 3) of unsigned(15 downto 0);

    signal mul_en_out_reg : std_logic_vector(2 downto 0);
    signal mul_a_reg      : unsigned(7 downto 0);
    signal mul_b_reg      : unsigned(7 downto 0);
    signal temp           : partial_product_array;
    signal sum            : partial_sum_array;
    signal mul_out_reg    : unsigned(15 downto 0);
begin
    -- Valid indication follows the three registered datapath stages.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mul_en_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            mul_en_out_reg <= mul_en_out_reg(1 downto 0) & mul_en_in;
        end if;
    end process;

    -- Stage 1: capture enabled input operands.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mul_a_reg <= (others => '0');
            mul_b_reg <= (others => '0');
        elsif rising_edge(clk) then
            if mul_en_in = '1' then
                mul_a_reg <= unsigned(mul_a);
                mul_b_reg <= unsigned(mul_b);
            end if;
        end if;
    end process;

    -- Generate the eight aligned unsigned partial products.
    partial_products : for i in 0 to 7 generate
        temp(i) <= shift_left(resize(mul_a_reg, 16), i)
                   when mul_b_reg(i) = '1'
                   else (others => '0');
    end generate partial_products;

    -- Stage 2: register sums of pairs of partial products.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            sum <= (others => (others => '0'));
        elsif rising_edge(clk) then
            for i in 0 to 3 loop
                sum(i) <= temp(2 * i) + temp(2 * i + 1);
            end loop;
        end if;
    end process;

    -- Stage 3: register the final product.
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            mul_out_reg <= (sum(0) + sum(1)) + (sum(2) + sum(3));
        end if;
    end process;

    mul_en_out <= mul_en_out_reg(2);
    mul_out    <= std_logic_vector(mul_out_reg)
                  when mul_en_out_reg(2) = '1'
                  else (others => '0');
end architecture rtl;
