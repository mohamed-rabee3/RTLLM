library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_pipe_64bit is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end entity adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    signal en_pipe : std_logic_vector(3 downto 0);

    signal a_stage1 : unsigned(47 downto 0);
    signal b_stage1 : unsigned(47 downto 0);
    signal a_stage2 : unsigned(31 downto 0);
    signal b_stage2 : unsigned(31 downto 0);
    signal a_stage3 : unsigned(15 downto 0);
    signal b_stage3 : unsigned(15 downto 0);

    -- Each partial sum includes the carry into the next stage.
    signal sum_stage1 : unsigned(16 downto 0);
    signal sum_stage2 : unsigned(32 downto 0);
    signal sum_stage3 : unsigned(48 downto 0);
    signal sum_stage4 : unsigned(64 downto 0);
begin
    result <= std_logic_vector(sum_stage4);
    o_en   <= en_pipe(3);

    -- Four registered stages, each adding a 16-bit portion.
    process (clk, rst_n)
        variable next_sum1 : unsigned(16 downto 0);
        variable next_sum2 : unsigned(16 downto 0);
        variable next_sum3 : unsigned(16 downto 0);
        variable next_sum4 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            en_pipe <= (others => '0');

            a_stage1 <= (others => '0');
            b_stage1 <= (others => '0');
            a_stage2 <= (others => '0');
            b_stage2 <= (others => '0');
            a_stage3 <= (others => '0');
            b_stage3 <= (others => '0');

            sum_stage1 <= (others => '0');
            sum_stage2 <= (others => '0');
            sum_stage3 <= (others => '0');
            sum_stage4 <= (others => '0');

        elsif rising_edge(clk) then
            en_pipe <= en_pipe(2 downto 0) & i_en;

            -- Stage 1: operand bits 15 downto 0.
            next_sum1 := resize(unsigned(adda(15 downto 0)), 17)
                       + resize(unsigned(addb(15 downto 0)), 17);

            sum_stage1 <= next_sum1;
            a_stage1   <= unsigned(adda(63 downto 16));
            b_stage1   <= unsigned(addb(63 downto 16));

            -- Stage 2: operand bits 31 downto 16.
            next_sum2 := resize(a_stage1(15 downto 0), 17)
                       + resize(b_stage1(15 downto 0), 17)
                       + resize(sum_stage1(16 downto 16), 17);

            sum_stage2 <= next_sum2 & sum_stage1(15 downto 0);
            a_stage2   <= a_stage1(47 downto 16);
            b_stage2   <= b_stage1(47 downto 16);

            -- Stage 3: operand bits 47 downto 32.
            next_sum3 := resize(a_stage2(15 downto 0), 17)
                       + resize(b_stage2(15 downto 0), 17)
                       + resize(sum_stage2(32 downto 32), 17);

            sum_stage3 <= next_sum3 & sum_stage2(31 downto 0);
            a_stage3   <= a_stage2(31 downto 16);
            b_stage3   <= b_stage2(31 downto 16);

            -- Stage 4: operand bits 63 downto 48 and final carry.
            next_sum4 := resize(a_stage3, 17)
                       + resize(b_stage3, 17)
                       + resize(sum_stage3(48 downto 48), 17);

            sum_stage4 <= next_sum4 & sum_stage3(47 downto 0);
        end if;
    end process;
end architecture rtl;
