library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_pipe_64bit is
    Port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        i_en  : in  std_logic;
        adda  : in  std_logic_vector(63 downto 0);
        addb  : in  std_logic_vector(63 downto 0);
        result: out std_logic_vector(64 downto 0);
        o_en  : out std_logic
    );
end adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    -- Stage 1 registers
    signal a_rem1 : unsigned(47 downto 0);
    signal b_rem1 : unsigned(47 downto 0);
    signal sum0_reg : unsigned(15 downto 0);
    signal carry0_reg : unsigned(0 downto 0);
    signal en1 : std_logic;

    -- Stage 2 registers
    signal a_rem2 : unsigned(31 downto 0);
    signal b_rem2 : unsigned(31 downto 0);
    signal sum1_reg : unsigned(15 downto 0);
    signal carry1_reg : unsigned(0 downto 0);
    signal sum0_pass1 : unsigned(15 downto 0);
    signal en2 : std_logic;

    -- Stage 3 registers
    signal a_rem3 : unsigned(15 downto 0);
    signal b_rem3 : unsigned(15 downto 0);
    signal sum2_reg : unsigned(15 downto 0);
    signal carry2_reg : unsigned(0 downto 0);
    signal sum1_pass1 : unsigned(15 downto 0);
    signal sum0_pass2 : unsigned(15 downto 0);
    signal en3 : std_logic;

    -- Stage 4 registers
    signal result_reg : unsigned(64 downto 0);
    signal o_en_reg : std_logic;
begin
    process(clk, rst_n)
        variable sum0 : unsigned(16 downto 0);
        variable sum1 : unsigned(16 downto 0);
        variable sum2 : unsigned(16 downto 0);
        variable sum3 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            a_rem1 <= (others => '0');
            b_rem1 <= (others => '0');
            sum0_reg <= (others => '0');
            carry0_reg <= (others => '0');
            en1 <= '0';

            a_rem2 <= (others => '0');
            b_rem2 <= (others => '0');
            sum1_reg <= (others => '0');
            carry1_reg <= (others => '0');
            sum0_pass1 <= (others => '0');
            en2 <= '0';

            a_rem3 <= (others => '0');
            b_rem3 <= (others => '0');
            sum2_reg <= (others => '0');
            carry2_reg <= (others => '0');
            sum1_pass1 <= (others => '0');
            sum0_pass2 <= (others => '0');
            en3 <= '0';

            result_reg <= (others => '0');
            o_en_reg <= '0';
        elsif rising_edge(clk) then
            -- Stage 1: add bits 15 downto 0
            sum0 := ('0' & unsigned(adda(15 downto 0))) + ('0' & unsigned(addb(15 downto 0)));
            sum0_reg <= sum0(15 downto 0);
            carry0_reg <= (0 => sum0(16));
            a_rem1 <= unsigned(adda(63 downto 16));
            b_rem1 <= unsigned(addb(63 downto 16));
            en1 <= i_en;

            -- Stage 2: add bits 31 downto 16 with carry from stage 1
            sum1 := ('0' & a_rem1(15 downto 0)) + ('0' & b_rem1(15 downto 0)) + resize(carry0_reg, 17);
            sum1_reg <= sum1(15 downto 0);
            carry1_reg <= (0 => sum1(16));
            sum0_pass1 <= sum0_reg;
            a_rem2 <= a_rem1(47 downto 16);
            b_rem2 <= b_rem1(47 downto 16);
            en2 <= en1;

            -- Stage 3: add bits 47 downto 32 with carry from stage 2
            sum2 := ('0' & a_rem2(15 downto 0)) + ('0' & b_rem2(15 downto 0)) + resize(carry1_reg, 17);
            sum2_reg <= sum2(15 downto 0);
            carry2_reg <= (0 => sum2(16));
            sum1_pass1 <= sum1_reg;
            sum0_pass2 <= sum0_pass1;
            a_rem3 <= a_rem2(31 downto 16);
            b_rem3 <= b_rem2(31 downto 16);
            en3 <= en2;

            -- Stage 4: add bits 63 downto 48 with carry from stage 3
            sum3 := ('0' & a_rem3) + ('0' & b_rem3) + resize(carry2_reg, 17);
            result_reg <= sum3(16) & sum3(15 downto 0) & sum2_reg & sum1_pass1 & sum0_pass2;
            o_en_reg <= en3;
        end if;
    end process;

    result <= std_logic_vector(result_reg);
    o_en <= o_en_reg;
end rtl;
