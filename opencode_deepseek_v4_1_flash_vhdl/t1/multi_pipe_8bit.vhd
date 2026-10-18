library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_pipe_8bit is
    Port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        mul_en_in  : in  std_logic;
        mul_a      : in  std_logic_vector(7 downto 0);
        mul_b      : in  std_logic_vector(7 downto 0);
        mul_en_out : out std_logic;
        mul_out    : out std_logic_vector(15 downto 0)
    );
end multi_pipe_8bit;

architecture rtl of multi_pipe_8bit is
    signal mul_a_reg : unsigned(7 downto 0);
    signal mul_b_reg : unsigned(7 downto 0);

    signal mul_en_out_reg : std_logic_vector(2 downto 0);

    type temp_array is array (0 to 7) of unsigned(15 downto 0);
    signal temp : temp_array;

    type sum_array is array (0 to 3) of unsigned(15 downto 0);
    signal sum : sum_array;

    signal mul_out_reg : unsigned(15 downto 0);
begin
    -- Partial product generation
    temp(0) <= (others => '0') when mul_b_reg(0) = '0' else resize(mul_a_reg, 16);
    temp(1) <= (others => '0') when mul_b_reg(1) = '0' else shift_left(resize(mul_a_reg, 16), 1);
    temp(2) <= (others => '0') when mul_b_reg(2) = '0' else shift_left(resize(mul_a_reg, 16), 2);
    temp(3) <= (others => '0') when mul_b_reg(3) = '0' else shift_left(resize(mul_a_reg, 16), 3);
    temp(4) <= (others => '0') when mul_b_reg(4) = '0' else shift_left(resize(mul_a_reg, 16), 4);
    temp(5) <= (others => '0') when mul_b_reg(5) = '0' else shift_left(resize(mul_a_reg, 16), 5);
    temp(6) <= (others => '0') when mul_b_reg(6) = '0' else shift_left(resize(mul_a_reg, 16), 6);
    temp(7) <= (others => '0') when mul_b_reg(7) = '0' else shift_left(resize(mul_a_reg, 16), 7);

    -- Input registers and enable pipeline
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_a_reg <= (others => '0');
            mul_b_reg <= (others => '0');
            mul_en_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            mul_en_out_reg <= mul_en_out_reg(1 downto 0) & mul_en_in;
            if mul_en_in = '1' then
                mul_a_reg <= unsigned(mul_a);
                mul_b_reg <= unsigned(mul_b);
            end if;
        end if;
    end process;

    -- Partial sum calculation
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sum(0) <= (others => '0');
            sum(1) <= (others => '0');
            sum(2) <= (others => '0');
            sum(3) <= (others => '0');
        elsif rising_edge(clk) then
            if mul_en_out_reg(0) = '1' then
                sum(0) <= temp(0) + temp(1);
                sum(1) <= temp(2) + temp(3);
                sum(2) <= temp(4) + temp(5);
                sum(3) <= temp(6) + temp(7);
            end if;
        end if;
    end process;

    -- Final product calculation
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_out_reg <= (others => '0');
        elsif rising_edge(clk) then
            if mul_en_out_reg(1) = '1' then
                mul_out_reg <= sum(0) + sum(1) + sum(2) + sum(3);
            end if;
        end if;
    end process;

    -- Output assignments
    mul_en_out <= mul_en_out_reg(2);
    mul_out <= std_logic_vector(mul_out_reg) when mul_en_out_reg(2) = '1' else (others => '0');
end rtl;
