library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_pipe_8bit is
    Port (
        clk        : in  STD_LOGIC;
        rst_n      : in  STD_LOGIC;
        mul_en_in  : in  STD_LOGIC;
        mul_a      : in  STD_LOGIC_VECTOR(7 downto 0);
        mul_b      : in  STD_LOGIC_VECTOR(7 downto 0);
        mul_en_out : out STD_LOGIC;
        mul_out    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end multi_pipe_8bit;

architecture Behavioral of multi_pipe_8bit is
    signal mul_a_reg      : unsigned(7 downto 0);
    signal mul_b_reg      : unsigned(7 downto 0);
    signal mul_en_out_reg : std_logic_vector(2 downto 0);

    signal temp0, temp1, temp2, temp3 : unsigned(15 downto 0);
    signal temp4, temp5, temp6, temp7 : unsigned(15 downto 0);

    signal sum0, sum1, sum2, sum3 : unsigned(15 downto 0);
    signal mul_out_reg            : unsigned(15 downto 0);
begin

    temp0 <= resize(mul_a_reg, 16) when mul_b_reg(0) = '1' else (others => '0');
    temp1 <= shift_left(resize(mul_a_reg, 16), 1) when mul_b_reg(1) = '1' else (others => '0');
    temp2 <= shift_left(resize(mul_a_reg, 16), 2) when mul_b_reg(2) = '1' else (others => '0');
    temp3 <= shift_left(resize(mul_a_reg, 16), 3) when mul_b_reg(3) = '1' else (others => '0');
    temp4 <= shift_left(resize(mul_a_reg, 16), 4) when mul_b_reg(4) = '1' else (others => '0');
    temp5 <= shift_left(resize(mul_a_reg, 16), 5) when mul_b_reg(5) = '1' else (others => '0');
    temp6 <= shift_left(resize(mul_a_reg, 16), 6) when mul_b_reg(6) = '1' else (others => '0');
    temp7 <= shift_left(resize(mul_a_reg, 16), 7) when mul_b_reg(7) = '1' else (others => '0');

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_a_reg      <= (others => '0');
            mul_b_reg      <= (others => '0');
            mul_en_out_reg <= (others => '0');
            sum0           <= (others => '0');
            sum1           <= (others => '0');
            sum2           <= (others => '0');
            sum3           <= (others => '0');
            mul_out_reg    <= (others => '0');
        elsif rising_edge(clk) then
            if mul_en_in = '1' then
                mul_a_reg <= unsigned(mul_a);
                mul_b_reg <= unsigned(mul_b);
            end if;

            mul_en_out_reg <= mul_en_out_reg(1 downto 0) & mul_en_in;

            sum0 <= temp0 + temp1;
            sum1 <= temp2 + temp3;
            sum2 <= temp4 + temp5;
            sum3 <= temp6 + temp7;

            mul_out_reg <= sum0 + sum1 + sum2 + sum3;
        end if;
    end process;

    mul_en_out <= mul_en_out_reg(2);
    mul_out    <= std_logic_vector(mul_out_reg) when mul_en_out_reg(2) = '1' else (others => '0');

end Behavioral;
