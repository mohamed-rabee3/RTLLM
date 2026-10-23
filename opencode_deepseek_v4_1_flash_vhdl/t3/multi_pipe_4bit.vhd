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
    constant half_size : integer := size / 2;

    signal mul_a_ext : unsigned(2*size-1 downto 0);
    signal mul_b_ext : unsigned(2*size-1 downto 0);

    type pp_array is array (0 to size-1) of unsigned(2*size-1 downto 0);
    signal pp : pp_array;

    type sum_array is array (0 to half_size-1) of unsigned(2*size-1 downto 0);
    signal sum_reg : sum_array;

    signal mul_out_reg : unsigned(2*size-1 downto 0);
begin
    mul_a_ext <= resize(unsigned(mul_a), 2*size);
    mul_b_ext <= resize(unsigned(mul_b), 2*size);

    gen_pp : for i in 0 to size-1 generate
        pp(i) <= shift_left(mul_a_ext, i) when mul_b_ext(i) = '1' else (others => '0');
    end generate gen_pp;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for i in 0 to half_size-1 loop
                sum_reg(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            for i in 0 to half_size-1 loop
                sum_reg(i) <= pp(2*i) + pp(2*i+1);
            end loop;
        end if;
    end process;

    process(clk, rst_n)
        variable total : unsigned(2*size-1 downto 0);
    begin
        if rst_n = '0' then
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            total := (others => '0');
            for i in 0 to half_size-1 loop
                total := total + sum_reg(i);
            end loop;
            mul_out_reg <= total;
        end if;
    end process;

    mul_out <= std_logic_vector(mul_out_reg);
end rtl;
