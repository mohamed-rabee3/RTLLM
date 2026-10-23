library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_pipe_4bit is
    generic (
        size : integer := 4
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        mul_a   : in  std_logic_vector(size-1 downto 0);
        mul_b   : in  std_logic_vector(size-1 downto 0);
        mul_out : out std_logic_vector(2*size-1 downto 0)
    );
end multi_pipe_4bit;

architecture rtl of multi_pipe_4bit is
    signal a_ext : unsigned(2*size-1 downto 0);
    signal b_ext : unsigned(2*size-1 downto 0);
    type pp_array is array (0 to size-1) of unsigned(2*size-1 downto 0);
    signal pp : pp_array;
    signal sum_reg0 : unsigned(2*size-1 downto 0);
    signal sum_reg1 : unsigned(2*size-1 downto 0);
    signal mul_out_reg : unsigned(2*size-1 downto 0);
begin
    -- Extend inputs with zeros at the most significant bit positions
    a_ext <= resize(unsigned(mul_a), 2*size);
    b_ext <= resize(unsigned(mul_b), 2*size);

    -- Generate partial products for each bit of the multiplier
    gen_pp : for i in 0 to size-1 generate
        pp(i) <= shift_left(a_ext, i) when b_ext(i) = '1' else (others => '0');
    end generate gen_pp;

    -- Stage 1: register sums of pairs of partial products
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sum_reg0 <= (others => '0');
            sum_reg1 <= (others => '0');
        elsif rising_edge(clk) then
            sum_reg0 <= pp(0) + pp(1);
            sum_reg1 <= pp(2) + pp(3);
        end if;
    end process;

    -- Stage 2: sum the registered intermediate sums and register final product
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            mul_out_reg <= sum_reg0 + sum_reg1;
        end if;
    end process;

    mul_out <= std_logic_vector(mul_out_reg);
end rtl;
