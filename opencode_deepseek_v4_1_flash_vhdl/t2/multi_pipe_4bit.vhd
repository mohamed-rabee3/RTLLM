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
    signal mul_a_ext : unsigned(2*size-1 downto 0);
    signal mul_b_ext : unsigned(2*size-1 downto 0);
    type pp_array is array (0 to size-1) of unsigned(2*size-1 downto 0);
    signal pp : pp_array;
    type sum_array is array (0 to size/2-1) of unsigned(2*size-1 downto 0);
    signal sum_reg : sum_array;
begin
    -- Extend inputs by adding size zero bits at the most significant positions
    mul_a_ext <= resize(unsigned(mul_a), 2*size);
    mul_b_ext <= resize(unsigned(mul_b), 2*size);

    -- Generate partial products
    gen_pp: for i in 0 to size-1 generate
        pp(i) <= shift_left(mul_a_ext, i) when mul_b_ext(i) = '1' else (others => '0');
    end generate;

    -- First pipeline stage: sum pairs of partial products
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for i in 0 to size/2-1 loop
                sum_reg(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            for i in 0 to size/2-1 loop
                sum_reg(i) <= pp(2*i) + pp(2*i+1);
            end loop;
        end if;
    end process;

    -- Second pipeline stage: final sum
    process(clk, rst_n)
        variable temp_sum : unsigned(2*size-1 downto 0);
    begin
        if rst_n = '0' then
            mul_out <= (others => '0');
        elsif rising_edge(clk) then
            temp_sum := (others => '0');
            for i in 0 to size/2-1 loop
                temp_sum := temp_sum + sum_reg(i);
            end loop;
            mul_out <= std_logic_vector(temp_sum);
        end if;
    end process;
end rtl;
