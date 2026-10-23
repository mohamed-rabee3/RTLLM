library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_pipe_8bit is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           mul_en_in : in STD_LOGIC;
           mul_a : in STD_LOGIC_VECTOR (7 downto 0);
           mul_b : in STD_LOGIC_VECTOR (7 downto 0);
           mul_en_out : out STD_LOGIC;
           mul_out : out STD_LOGIC_VECTOR (15 downto 0));
end multi_pipe_8bit;

architecture Behavioral of multi_pipe_8bit is
    signal mul_a_reg : unsigned(7 downto 0);
    signal mul_b_reg : unsigned(7 downto 0);
    type temp_array is array (0 to 7) of unsigned(15 downto 0);
    signal temp : temp_array;
    type sum_array is array (0 to 3) of unsigned(15 downto 0);
    signal sum : sum_array;
    signal mul_out_reg : unsigned(15 downto 0);
    signal mul_en_out_reg : std_logic_vector(3 downto 0);
begin

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
            mul_en_out_reg <= mul_en_out_reg(2 downto 0) & mul_en_in;
        end if;
    end process;

    gen_temp: for i in 0 to 7 generate
        temp(i) <= shift_left(resize(mul_a_reg, 16), i) when mul_b_reg(i) = '1' else (others => '0');
    end generate;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for i in 0 to 3 loop
                sum(i) <= (others => '0');
            end loop;
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            sum(0) <= temp(0) + temp(1);
            sum(1) <= temp(2) + temp(3);
            sum(2) <= temp(4) + temp(5);
            sum(3) <= temp(6) + temp(7);
            mul_out_reg <= sum(0) + sum(1) + sum(2) + sum(3);
        end if;
    end process;

    mul_en_out <= mul_en_out_reg(3);
    mul_out <= std_logic_vector(mul_out_reg) when mul_en_out = '1' else (others => '0');

end Behavioral;
