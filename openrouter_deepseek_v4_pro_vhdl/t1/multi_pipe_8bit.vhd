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
end multi_pipe_8bit;

architecture Behavioral of multi_pipe_8bit is

    -- Pipeline enable shift register (3 stages: input regs -> sum regs -> out reg)
    signal mul_en_out_reg : std_logic_vector(2 downto 0) := (others => '0');
    signal mul_en_out_int : std_logic;

    -- Input data registers
    signal mul_a_reg : unsigned(7 downto 0) := (others => '0');
    signal mul_b_reg : unsigned(7 downto 0) := (others => '0');

    -- Partial products (wires)
    type temp_array is array (0 to 7) of unsigned(7 downto 0);
    signal temp : temp_array;

    -- Partial sum combinational signals
    signal sum0_comb : unsigned(9 downto 0);
    signal sum1_comb : unsigned(9 downto 0);
    signal sum2_comb : unsigned(9 downto 0);
    signal sum3_comb : unsigned(9 downto 0);

    -- Partial sum registers (pipeline stage 1)
    signal sum0_reg : unsigned(9 downto 0) := (others => '0');
    signal sum1_reg : unsigned(9 downto 0) := (others => '0');
    signal sum2_reg : unsigned(9 downto 0) := (others => '0');
    signal sum3_reg : unsigned(9 downto 0) := (others => '0');

    -- Final product combinational signal
    signal mul_out_comb : unsigned(15 downto 0);

    -- Final product register (pipeline stage 2)
    signal mul_out_reg : unsigned(15 downto 0) := (others => '0');

begin

    -----------------------------------------------------------------------------
    -- Partial Product Generation (combinational)
    -- Generate 8 partial products by ANDing mul_a_reg with each bit of mul_b_reg
    -----------------------------------------------------------------------------
    gen_temp : for i in 0 to 7 generate
        temp(i) <= mul_a_reg when mul_b_reg(i) = '1' else (others => '0');
    end generate;

    -----------------------------------------------------------------------------
    -- Partial Sum Calculation (combinational)
    -- Group partial products in pairs and add them with appropriate shifts
    -----------------------------------------------------------------------------
    sum0_comb <= resize(temp(0), 10) + resize(temp(1) & "0", 10);
    sum1_comb <= resize(temp(2), 10) + resize(temp(3) & "0", 10);
    sum2_comb <= resize(temp(4), 10) + resize(temp(5) & "0", 10);
    sum3_comb <= resize(temp(6), 10) + resize(temp(7) & "0", 10);

    -----------------------------------------------------------------------------
    -- Final Product Calculation (combinational)
    -- Sum all partial sums with their relative group shifts
    -----------------------------------------------------------------------------
    mul_out_comb <= resize(sum0_reg, 16) +
                    resize(sum1_reg & "00", 16) +
                    resize(sum2_reg & "0000", 16) +
                    resize(sum3_reg & "000000", 16);

    -----------------------------------------------------------------------------
    -- Output Enable Assignment
    -- mul_en_out is the most significant bit of the enable shift register
    -----------------------------------------------------------------------------
    mul_en_out_int <= mul_en_out_reg(2);
    mul_en_out      <= mul_en_out_int;

    -----------------------------------------------------------------------------
    -- Output Product Assignment
    -- Drive mul_out only when the output enable is active
    -----------------------------------------------------------------------------
    mul_out <= std_logic_vector(mul_out_reg) when mul_en_out_int = '1' else (others => '0');

    -----------------------------------------------------------------------------
    -- Synchronous Pipeline Process (with asynchronous reset)
    -----------------------------------------------------------------------------
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mul_en_out_reg <= (others => '0');
            mul_a_reg      <= (others => '0');
            mul_b_reg      <= (others => '0');
            sum0_reg       <= (others => '0');
            sum1_reg       <= (others => '0');
            sum2_reg       <= (others => '0');
            sum3_reg       <= (others => '0');
            mul_out_reg    <= (others => '0');
        elsif rising_edge(clk) then
            -- Shift the enable flag through the pipeline
            mul_en_out_reg <= mul_en_out_reg(1 downto 0) & mul_en_in;

            -- Input registers: update only when input enable is active
            if mul_en_in = '1' then
                mul_a_reg <= unsigned(mul_a);
                mul_b_reg <= unsigned(mul_b);
            end if;

            -- Partial sum pipeline registers (always updated)
            sum0_reg <= sum0_comb;
            sum1_reg <= sum1_comb;
            sum2_reg <= sum2_comb;
            sum3_reg <= sum3_comb;

            -- Final product pipeline register (always updated)
            mul_out_reg <= mul_out_comb;
        end if;
    end process;

end Behavioral;