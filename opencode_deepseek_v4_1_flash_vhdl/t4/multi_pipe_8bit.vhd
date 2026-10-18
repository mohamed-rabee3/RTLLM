library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
    signal mul_a_reg : unsigned(7 downto 0);
    signal mul_b_reg : unsigned(7 downto 0);
    signal mul_en_out_reg : std_logic_vector(4 downto 0);
    signal mul_out_reg : unsigned(15 downto 0);

    type t_temp is array (0 to 7) of unsigned(15 downto 0);
    signal temp : t_temp;

    type t_sum is array (0 to 6) of unsigned(15 downto 0);
    signal sum_reg : t_sum;

    signal mul_en_out_int : std_logic;
    signal mul_out_int : std_logic_vector(15 downto 0);
begin

    mul_en_out_int <= mul_en_out_reg(4);
    mul_en_out <= mul_en_out_int;

    mul_out_int <= std_logic_vector(mul_out_reg) when mul_en_out_int = '1' else (others => '0');
    mul_out <= mul_out_int;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_a_reg <= (others => '0');
            mul_b_reg <= (others => '0');
            mul_en_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            if mul_en_in = '1' then
                mul_a_reg <= unsigned(mul_a);
                mul_b_reg <= unsigned(mul_b);
            end if;
            mul_en_out_reg <= mul_en_out_reg(3 downto 0) & mul_en_in;
        end if;
    end process;

    gen_temp: for k in 0 to 7 generate
        temp(k) <= shift_left(resize(mul_a_reg, 16), k) when mul_b_reg(k) = '1' else (others => '0');
    end generate;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for i in 0 to 6 loop
                sum_reg(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            sum_reg(0) <= temp(0) + temp(1);
            sum_reg(1) <= temp(2) + temp(3);
            sum_reg(2) <= temp(4) + temp(5);
            sum_reg(3) <= temp(6) + temp(7);
            sum_reg(4) <= sum_reg(0) + sum_reg(1);
            sum_reg(5) <= sum_reg(2) + sum_reg(3);
            sum_reg(6) <= sum_reg(4) + sum_reg(5);
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            mul_out_reg <= sum_reg(6);
        end if;
    end process;

end architecture rtl;
