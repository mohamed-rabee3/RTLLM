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
    -- Four pipeline stages, each adding a 16-bit operand slice.
    signal a_stage1 : unsigned(47 downto 0);
    signal b_stage1 : unsigned(47 downto 0);
    signal a_stage2 : unsigned(31 downto 0);
    signal b_stage2 : unsigned(31 downto 0);
    signal a_stage3 : unsigned(15 downto 0);
    signal b_stage3 : unsigned(15 downto 0);

    -- Each partial sum includes its outgoing carry as its top bit.
    signal sum_stage1 : unsigned(16 downto 0);
    signal sum_stage2 : unsigned(32 downto 0);
    signal sum_stage3 : unsigned(48 downto 0);

    signal valid_pipe : std_logic_vector(3 downto 0);
begin
    o_en <= valid_pipe(3);

    process (clk, rst_n)
        variable slice_sum1 : unsigned(16 downto 0);
        variable slice_sum2 : unsigned(16 downto 0);
        variable slice_sum3 : unsigned(16 downto 0);
        variable slice_sum4 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            a_stage1   <= (others => '0');
            b_stage1   <= (others => '0');
            a_stage2   <= (others => '0');
            b_stage2   <= (others => '0');
            a_stage3   <= (others => '0');
            b_stage3   <= (others => '0');
            sum_stage1 <= (others => '0');
            sum_stage2 <= (others => '0');
            sum_stage3 <= (others => '0');
            valid_pipe <= (others => '0');
            result     <= (others => '0');

        elsif rising_edge(clk) then
            valid_pipe <= valid_pipe(2 downto 0) & i_en;

            -- Stage 1: bits 15 through 0.
            slice_sum1 := resize(unsigned(adda(15 downto 0)), 17)
                        + resize(unsigned(addb(15 downto 0)), 17);

            sum_stage1 <= slice_sum1;
            a_stage1   <= unsigned(adda(63 downto 16));
            b_stage1   <= unsigned(addb(63 downto 16));

            -- Stage 2: bits 31 through 16.
            slice_sum2 := resize(a_stage1(15 downto 0), 17)
                        + resize(b_stage1(15 downto 0), 17)
                        + resize(sum_stage1(16 downto 16), 17);

            sum_stage2 <= slice_sum2 & sum_stage1(15 downto 0);
            a_stage2   <= a_stage1(47 downto 16);
            b_stage2   <= b_stage1(47 downto 16);

            -- Stage 3: bits 47 through 32.
            slice_sum3 := resize(a_stage2(15 downto 0), 17)
                        + resize(b_stage2(15 downto 0), 17)
                        + resize(sum_stage2(32 downto 32), 17);

            sum_stage3 <= slice_sum3 & sum_stage2(31 downto 0);
            a_stage3   <= a_stage2(31 downto 16);
            b_stage3   <= b_stage2(31 downto 16);

            -- Stage 4: bits 63 through 48 and the final carry.
            slice_sum4 := resize(a_stage3, 17)
                        + resize(b_stage3, 17)
                        + resize(sum_stage3(48 downto 48), 17);

            result <= std_logic_vector(
                slice_sum4 & sum_stage3(47 downto 0)
            );
        end if;
    end process;
end architecture rtl;
